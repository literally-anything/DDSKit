import fastdds
import DDSKitInternal
import Synchronization

public final class DataWriter<DataType: IDLType>: @unchecked Sendable {
    public typealias PublicationMatchedCallback = @Sendable (borrowing fastdds.PublicationMatchedStatus) -> Void
    public typealias OfferedDeadlineMissedCallback = @Sendable (borrowing fastdds.DeadlineMissedStatus) -> Void
    public typealias OfferedIncompatibleQosCallback = @Sendable (borrowing fastdds.IncompatibleQosStatus) -> Void
    public typealias LivelinessLostCallback = @Sendable (borrowing fastdds.LivelinessLostStatus) -> Void
    public typealias UnacknowledgedSampleRemovedCallback = @Sendable (borrowing fastdds.InstanceHandle_t) -> Void

    public let raw: OpaquePointer
    public let publisher: Publisher
    public let topic: Topic
    private var callbacks = WriterCallbacks()
    private let listener: UnsafeMutablePointer<_DataWriter.Listener>

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
            .init(from: _DataWriter.getQos(raw))
        }
        set(newValue) {
            let ret = _DataWriter.setQos(raw, newValue.raw)
            assert(ret == fastdds.RETCODE_OK)
        }
    }

    public convenience init?(publisher: Publisher, topic: Topic, profile: String) throws {
        let dataReaderPtr = _DataWriter.create(publisher.raw, .init(profile), topic.raw)
        guard dataReaderPtr != nil else {
            return nil
        }
        try self.init(from: dataReaderPtr!, publisher: publisher, topic: topic)
    }
    public convenience init?(publisher: Publisher, topic: Topic, qos: Qos? = nil) throws {
        let dataReaderPtr = _DataWriter.create(publisher.raw, (qos ?? .getBase(for: publisher)).raw, topic.raw)
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
            _DataWriter.createListener(OpaquePointer(ptr))
        }
        callbacks.setCallbacks { statusPtr in
            // Publication Matched
            let status = UnsafePointer<fastdds.PublicationMatchedStatus>(OpaquePointer(statusPtr)).pointee
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
        } onOfferedDeadlineMissed: { statusPtr in
            // Offered Deadline Missed
            self.offeredDeadlineMissedCallback.withLock { callback in
                callback?(UnsafePointer<fastdds.DeadlineMissedStatus>(OpaquePointer(statusPtr)).pointee)
            }
        } onOfferedIncompatibleQos: { statusPtr in
            // Offered Incompatible Qos
            self.offeredIncompatibleQosCallback.withLock { callback in
                callback?(UnsafePointer<fastdds.IncompatibleQosStatus>(OpaquePointer(statusPtr)).pointee)
            }
        } onLivelinessLost: { statusPtr in
            // Liveliness Lost
            self.livelinessLostCallback.withLock { callback in
                callback?(UnsafePointer<fastdds.LivelinessLostStatus>(OpaquePointer(statusPtr)).pointee)
            }
        } onUnacknowledgedSampleRemoved: { handlePtr in
            // Unacknowledged Sample Removed
            self.unacknowledgedSampleRemovedCallback.withLock { callback in
                callback?(UnsafePointer<fastdds.InstanceHandle_t>(OpaquePointer(handlePtr)).pointee)
            }
        }
        var mask = _StatusMask.publication_matched()
        _statusMaskAdd(&mask, _StatusMask.offered_deadline_missed())
        _statusMaskAdd(&mask, _StatusMask.offered_incompatible_qos())
        _statusMaskAdd(&mask, _StatusMask.liveliness_lost())
        try DDSError.check(code: _DataWriter.setListener(raw, listener, mask))
    }
    deinit {
        let ret = _DataWriter.destroy(raw)
        assert(ret == fastdds.RETCODE_OK, "Failed to destroy static DataReader: \(String(describing: DDSError(rawValue: ret)))")

        _DataWriter.destroyListener(listener)
    }

    public func write(message: borrowing DataType) throws {
        let ret = withUnsafePointer(to: message) { messagePtr in
            _DataWriter.write(raw, messagePtr, _DataWriter.WriteParams.write_params_default())
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
        public var raw: _DataWriter.DataWriterQos

        @inlinable public static func == (lhs: Qos, rhs: Qos) -> Bool {
            _DataWriter.compareQos(lhs.raw, rhs.raw)
        }

        @inlinable public init() {
            self.init(from: _DataWriter.DataWriterQos())
        }
        public init(from qos: _DataWriter.DataWriterQos) {
            raw = qos
        }

        @inlinable public static func getBase(for publisher: Publisher) -> Qos {
            Qos(from: _DataWriter.getDefaultQos(publisher.raw))
        }
    }
}
