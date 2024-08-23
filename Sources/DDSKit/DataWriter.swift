public import enum fastdds.fastdds
public import Synchronization
import DDSKitInternal

public final class DataWriter<DataType: IDLType>: @unchecked Sendable {
    public typealias PublicationMatchedCallback = @Sendable (borrowing fastdds.DDSPublicationMatchedStatus) -> Void
    public typealias OfferedDeadlineMissedCallback = @Sendable (borrowing fastdds.DDSDeadlineMissedStatus) -> Void
    public typealias OfferedIncompatibleQosCallback = @Sendable (borrowing fastdds.DDSIncompatibleQosStatus) -> Void
    public typealias LivelinessLostCallback = @Sendable (borrowing fastdds.DDSLivelinessLostStatus) -> Void
    public typealias UnacknowledgedSampleRemovedCallback = @Sendable (borrowing fastdds.DDSInstanceHandle_t) -> Void

    public let raw: OpaquePointer
    public let publisher: Publisher
    public let topic: Topic
    private var callbacks = WriterCallbacks()
    private let listener: UnsafeMutablePointer<fastdds._DataWriter.Listener>

    private let waitingState = Mutex<Bool>(false)
    private let waitingContinution = Mutex<CheckedContinuation<Void, Never>?>(nil)

    private let publicationMatchedCallback = Mutex<PublicationMatchedCallback?>(nil)
    private let offeredDeadlineMissedCallback = Mutex<OfferedDeadlineMissedCallback?>(nil)
    private let offeredIncompatibleQosCallback = Mutex<OfferedIncompatibleQosCallback?>(nil)
    private let livelinessLostCallback = Mutex<LivelinessLostCallback?>(nil)
    private let unacknowledgedSampleRemovedCallback = Mutex<UnacknowledgedSampleRemovedCallback?>(nil)

    @usableFromInline internal let atomicMatchedReaders = Atomic<Int32>(0)
    @inlinable public var matchedReaders: Int32 {
        atomicMatchedReaders.load(ordering: .relaxed)
    }
    @inlinable public var hasReaders: Bool {
        matchedReaders > 0
    }
    public var qos: Qos {
        get {
            .init(from: fastdds._DataWriter.getQos(raw))
        }
        set(newValue) {
            let ret = fastdds._DataWriter.setQos(raw, newValue.raw)
            assert(ret == DDSError.OK)
        }
    }

    public convenience init?(publisher: Publisher, topic: Topic, profile: String) throws {
        let dataReaderPtr = fastdds._DataWriter.create(publisher.raw, .init(profile), topic.raw)
        guard dataReaderPtr != nil else {
            return nil
        }
        try self.init(from: dataReaderPtr!, publisher: publisher, topic: topic)
    }
    public convenience init?(publisher: Publisher, topic: Topic, qos: Qos? = nil) throws {
        let dataReaderPtr = fastdds._DataWriter.create(publisher.raw, (qos ?? .getBase(for: publisher)).raw, topic.raw)
        guard dataReaderPtr != nil else {
            return nil
        }
        try self.init(from: dataReaderPtr!, publisher: publisher, topic: topic)
    }
    public init(from dataReaderPtr: OpaquePointer, publisher parent: Publisher, topic associatedTopic: Topic) throws {
        raw = dataReaderPtr
        publisher = parent
        topic = associatedTopic

        listener = withUnsafePointer(to: &callbacks) { ptr in
            fastdds._DataWriter.createListener(OpaquePointer(ptr))
        }
        callbacks.setCallbacks { [unowned self] statusPtr in
            // Publication Matched
            let status = UnsafePointer<fastdds.DDSPublicationMatchedStatus>(OpaquePointer(statusPtr)).pointee
            self.atomicMatchedReaders.store(status.current_count, ordering: .sequentiallyConsistent)
            if status.current_count > 0 {
                self.waitingContinution.withLock { continuation in
                    if continuation != nil {
                        continuation!.resume()
                        continuation = nil
                    }
                }
            }
            self.publicationMatchedCallback.withLock { callback in
                callback?(status)
            }
        } onOfferedDeadlineMissed: { [unowned self] statusPtr in
            // Offered Deadline Missed
            self.offeredDeadlineMissedCallback.withLock { callback in
                callback?(UnsafePointer<fastdds.DDSDeadlineMissedStatus>(OpaquePointer(statusPtr)).pointee)
            }
        } onOfferedIncompatibleQos: { [unowned self] statusPtr in
            // Offered Incompatible Qos
            self.offeredIncompatibleQosCallback.withLock { callback in
                callback?(UnsafePointer<fastdds.DDSIncompatibleQosStatus>(OpaquePointer(statusPtr)).pointee)
            }
        } onLivelinessLost: { [unowned self] statusPtr in
            // Liveliness Lost
            self.livelinessLostCallback.withLock { callback in
                callback?(UnsafePointer<fastdds.DDSLivelinessLostStatus>(OpaquePointer(statusPtr)).pointee)
            }
        } onUnacknowledgedSampleRemoved: { [unowned self] handlePtr in
            // Unacknowledged Sample Removed
            self.unacknowledgedSampleRemovedCallback.withLock { callback in
                callback?(UnsafePointer<fastdds.DDSInstanceHandle_t>(OpaquePointer(handlePtr)).pointee)
            }
        }
        var mask = fastdds._StatusMask.publication_matched()
        fastdds._statusMaskAdd(&mask, fastdds._StatusMask.offered_deadline_missed())
        fastdds._statusMaskAdd(&mask, fastdds._StatusMask.offered_incompatible_qos())
        fastdds._statusMaskAdd(&mask, fastdds._StatusMask.liveliness_lost())
        try DDSError.check(code: fastdds._DataWriter.setListener(raw, listener, mask))
    }
    deinit {
        let ret = fastdds._DataWriter.destroy(raw)
        assert(ret == DDSError.OK, "Failed to destroy static DataReader: \(String(describing: DDSError(rawValue: ret)))")

        fastdds._DataWriter.destroyListener(listener)
    }

    public func write(message: borrowing DataType) throws {
        let ret = withUnsafePointer(to: message) { messagePtr in
            fastdds._DataWriter.write(raw, messagePtr, fastdds._DataWriter.WriteParams.write_params_default())
        }
        try DDSError.check(code: ret)
    }

    @discardableResult public func waitForSubscriber() async -> Bool {
        if matchedReaders > 0 {
            return true
        }
        let couldLock = waitingState.withLockIfAvailable({ state in
            guard !state else {
                return false
            }
            state = true
            return true
        }) ?? false
        guard couldLock else {
            return false
        }

        await withCheckedContinuation { continuation in
            waitingContinution.withLock {
                $0 = continuation
            }
        }

        waitingState.withLockIfAvailable { state in
            assert(state)
            state = false
        }
        return true
    }

    public func onPublicationMatched(perform action: @escaping PublicationMatchedCallback) {
        publicationMatchedCallback.withLock { callback in
            callback = action
        }
    }
    public func onOfferedDeadlineMissed(perform action: @escaping OfferedDeadlineMissedCallback) {
        offeredDeadlineMissedCallback.withLock { callback in
            callback = action
        }
    }
    public func onOfferedIncompatibleQos(perform action: @escaping OfferedIncompatibleQosCallback) {
        offeredIncompatibleQosCallback.withLock { callback in
            callback = action
        }
    }
    public func onLivelinessLost(perform action: @escaping LivelinessLostCallback) {
        livelinessLostCallback.withLock { callback in
            callback = action
        }
    }
    public func onUnacknowledgedSampleRemoved(perform action: @escaping UnacknowledgedSampleRemovedCallback) {
        unacknowledgedSampleRemovedCallback.withLock { callback in
            callback = action
        }
    }

    public struct Qos: Sendable, Equatable {
        public var raw: fastdds._DataWriter.DataWriterQos

        public static func == (lhs: Qos, rhs: Qos) -> Bool {
            fastdds._DataWriter.compareQos(lhs.raw, rhs.raw)
        }

        public init() {
            self.init(from: fastdds._DataWriter.DataWriterQos())
        }
        public init(from qos: fastdds._DataWriter.DataWriterQos) {
            raw = qos
        }

        public static func getBase(for publisher: Publisher) -> Qos {
            Qos(from: fastdds._DataWriter.getDefaultQos(publisher.raw))
        }
    }
}
