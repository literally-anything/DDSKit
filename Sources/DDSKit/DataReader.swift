public import enum fastdds.fastdds
import DDSKitInternal
import Synchronization

public final class DataReader<DataType: IDLType>: @unchecked Sendable {
    public typealias MessageCallback = @Sendable (borrowing DataType) -> Void
    public typealias SubscriptionMatchedCallback = @Sendable (borrowing fastdds.DDSSubscriptionMatchedStatus) -> Void
    public typealias DeadlineMissedCallback = @Sendable (borrowing fastdds.DDSDeadlineMissedStatus) -> Void
    public typealias LivelinessChangedCallback = @Sendable (borrowing fastdds.DDSLivelinessChangedStatus) -> Void
    public typealias SampleRejectedCallback = @Sendable (borrowing fastdds.DDSSampleRejectedStatus) -> Void
    public typealias IncompatibleQosCallback = @Sendable (borrowing fastdds.DDSIncompatibleQosStatus) -> Void
    public typealias SampleLostCallback = @Sendable (borrowing fastdds.DDSSampleLostStatus) -> Void

    public let raw: OpaquePointer
    public let subscriber: Subscriber
    public let topic: Topic
    private var callbacks = ReaderCallbacks()
    private let listener: UnsafeMutablePointer<fastdds._DataReader.Listener>
    private let mask = Mutex(fastdds._StatusMask.data_available())

    private let streamState = Mutex<Bool>(false)

    private let messageCallback = Mutex<MessageCallback?>(nil)
    private let subscriptionMatchedCallback = Mutex<SubscriptionMatchedCallback?>(nil)
    private let deadlineMissedCallback = Mutex<DeadlineMissedCallback?>(nil)
    private let livelinessChangedCallback = Mutex<LivelinessChangedCallback?>(nil)
    private let sampleRejectedCallback = Mutex<SampleRejectedCallback?>(nil)
    private let incompatibleQosCallback = Mutex<IncompatibleQosCallback?>(nil)
    private let sampleLostCallback = Mutex<SampleLostCallback?>(nil)

    private let atomicMatchedWriters = Atomic<Int32>(0)
    public var matchedWriters: Int32 {
        atomicMatchedWriters.load(ordering: .relaxed)
    }
    public var hasWriters: Bool {
        matchedWriters > 0
    }
    public var qos: Qos {
        get {
            .init(from: fastdds._DataReader.getQos(raw))
        }
        set(newValue) {
            let ret = fastdds._DataReader.setQos(raw, newValue.raw)
            assert(ret == DDSError.OK)
        }
    }
    public var messages: AsyncThrowingStream<DataType, any Error> {
        AsyncThrowingStream(DataType.self, bufferingPolicy: .unbounded) { continuation in
            let couldLock = streamState.withLockIfAvailable({ state in
                if state {
                    return false
                }
                state = true
                return true
            }) ?? false
            guard couldLock else {
                continuation.finish(throwing: DDSKitError.SynchronizationError)
                return
            }
            messageCallback.withLock { callback in
                var data = DataType()
                var info = fastdds._SampleInfo()
                while (withUnsafeMutablePointer(to: &data) { dataPtr in fastdds._DataReader.takeNextSample(self.raw, dataPtr, &info) } == 0) {
                    continuation.yield(data)
                }
                callback = { message in
                    continuation.yield(message)
                }
            }
            continuation.onTermination = { [unowned self] _ in
                self.messageCallback.withLock { callback in
                    callback = nil
                }
                self.streamState.withLock { state in
                    assert(state, "Stream state lock was already released")
                    state = false
                }
            }
        }
    }

    public convenience init?(subscriber: Subscriber, topic: Topic, profile: String) throws {
        let dataReaderPtr = fastdds._DataReader.create(subscriber.raw, .init(profile), topic.raw)
        guard (dataReaderPtr != nil) else {
            return nil
        }
        try self.init(from: dataReaderPtr!, subscriber: subscriber, topic: topic)
    }
    public convenience init?(subscriber: Subscriber, topic: Topic, qos: Qos? = nil) throws {
        let dataReaderPtr = fastdds._DataReader.create(subscriber.raw, (qos ?? .getBase(for: subscriber)).raw, topic.raw)
        guard (dataReaderPtr != nil) else {
            return nil
        }
        try self.init(from: dataReaderPtr!, subscriber: subscriber, topic: topic)
    }
    public init(from dataReaderPtr: OpaquePointer, subscriber parent: Subscriber, topic associatedTopic: Topic) throws {
        raw = dataReaderPtr
        subscriber = parent
        topic = associatedTopic

        listener = withUnsafePointer(to: &callbacks) { ptr in
            fastdds._DataReader.createListener(OpaquePointer(ptr))
        }
        callbacks.setCallbacks { [unowned self] in
            // Data Available
            self.messageCallback.withLock { callback in
                guard callback != nil else { return }
                var data = DataType()
                var info = fastdds._SampleInfo()
                while (withUnsafeMutablePointer(to: &data) { dataPtr in fastdds._DataReader.takeNextSample(self.raw, dataPtr, &info) } == 0) {
                    callback?(data)
                }
            }
        } onSubscriptionMatched: { [unowned self] statusPtr in
            // Subscription Matched
            let status = UnsafePointer<fastdds.DDSSubscriptionMatchedStatus>(OpaquePointer(statusPtr)).pointee
            self.atomicMatchedWriters.store(status.current_count, ordering: .sequentiallyConsistent)
            self.subscriptionMatchedCallback.withLock { callback in
                callback?(status)
            }
        } onRequestedDeadlineMissed: { [unowned self] statusPtr in
            // Requested Deadline Missed
            self.deadlineMissedCallback.withLock { callback in
                callback?(UnsafePointer<fastdds.DDSDeadlineMissedStatus>(OpaquePointer(statusPtr)).pointee)
            }
        } onLivelinessChanged: { [unowned self] statusPtr in
            // Liveliness Changed
            self.livelinessChangedCallback.withLock { callback in
                callback?(UnsafePointer<fastdds.DDSLivelinessChangedStatus>(OpaquePointer(statusPtr)).pointee)
            }
        } onSampleRejected: { [unowned self] statusPtr in
            // Sample Rejected
            self.sampleRejectedCallback.withLock { callback in
                callback?(UnsafePointer<fastdds.DDSSampleRejectedStatus>(OpaquePointer(statusPtr)).pointee)
            }
        } onRequestedIncompatibleQos: { [unowned self] statusPtr in
            // Requested Incompatible Qos
            self.incompatibleQosCallback.withLock { callback in
                callback?(UnsafePointer<fastdds.DDSIncompatibleQosStatus>(OpaquePointer(statusPtr)).pointee)
            }
        } onSampleLost: { [unowned self] statusPtr in
            // Sample Lost
            self.sampleLostCallback.withLock { callback in
                callback?(UnsafePointer<fastdds.DDSSampleLostStatus>(OpaquePointer(statusPtr)).pointee)
            }
        }
        try setListenerMask()
    }
    deinit {
        let ret = fastdds._DataReader.destroy(raw)
        assert(ret == DDSError.OK, "Failed to destroy static DataReader: \(String(describing: DDSError(rawValue: ret)))")

        fastdds._DataReader.destroyListener(listener)
    }

    private func setListenerMask() throws {
        try mask.withLock { mask in
            try DDSError.check(code: fastdds._DataReader.setListener(raw, listener, mask))
        }
    }

    public func onMessage(perform action: @escaping MessageCallback) {
        streamState.withLock { state in
            guard !state else {
                assertionFailure("Tried to set onMessage callback while an async stream is running")
                return
            }
            messageCallback.withLock { callback in
                callback = action
            }
        }
    }
    public func onSubscriptionMatched(perform action: @escaping SubscriptionMatchedCallback) throws {
        subscriptionMatchedCallback.withLock { callback in
            callback = action
        }
        mask.withLock { mask in
            fastdds._statusMaskAdd(&mask, fastdds._StatusMask.subscription_matched())
        }
        try setListenerMask()
    }
    public func onDeadlineMissed(perform action: @escaping DeadlineMissedCallback) throws {
        deadlineMissedCallback.withLock { callback in
            callback = action
        }
        mask.withLock { mask in
            fastdds._statusMaskAdd(&mask, fastdds._StatusMask.requested_deadline_missed())
        }
        try setListenerMask()
    }
    public func onLivelinessChanged(perform action: @escaping LivelinessChangedCallback) throws {
        livelinessChangedCallback.withLock { callback in
            callback = action
        }
        mask.withLock { mask in
            fastdds._statusMaskAdd(&mask, fastdds._StatusMask.liveliness_changed())
        }
        try setListenerMask()
    }
    public func onSampleRejected(perform action: @escaping SampleRejectedCallback) throws {
        sampleRejectedCallback.withLock { callback in
            callback = action
        }
        mask.withLock { mask in
            fastdds._statusMaskAdd(&mask, fastdds._StatusMask.sample_rejected())
        }
        try setListenerMask()
    }
    public func onIncompatibleQos(perform action: @escaping IncompatibleQosCallback) throws {
        incompatibleQosCallback.withLock { callback in
            callback = action
        }
        mask.withLock { mask in
            fastdds._statusMaskAdd(&mask, fastdds._StatusMask.requested_incompatible_qos())
        }
        try setListenerMask()
    }
    public func onSampleLost(perform action: @escaping SampleLostCallback) throws {
        sampleLostCallback.withLock { callback in
            callback = action
        }
        mask.withLock { mask in
            fastdds._statusMaskAdd(&mask, fastdds._StatusMask.sample_lost())
        }
        try setListenerMask()
    }

    public struct Qos: Sendable, Equatable {
        public var raw: fastdds._DataReader.DataReaderQos

        public static func == (lhs: Qos, rhs: Qos) -> Bool {
            fastdds._DataReader.compareQos(lhs.raw, rhs.raw)
        }

        public init() {
            self.init(from: fastdds._DataReader.DataReaderQos())
        }
        public init(from qos: fastdds._DataReader.DataReaderQos) {
            raw = qos
        }

        public static func getBase(for subscriber: Subscriber) -> Qos {
            Qos(from: fastdds._DataReader.getDefaultQos(subscriber.raw))
        }
    }
}
