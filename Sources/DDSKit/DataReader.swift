import fastdds
import DDSKitInternal
import Synchronization

public final class DataReader<DataType: IDLType>: @unchecked Sendable {
    public typealias MessageCallback = @Sendable (borrowing DataType) -> Void
    public typealias SubscriptionMatchedCallback = @Sendable (borrowing fastdds.SubscriptionMatchedStatus) -> Void
    public typealias DeadlineMissedCallback = @Sendable (borrowing fastdds.RequestedDeadlineMissedStatus) -> Void
    public typealias LivelinessChangedCallback = @Sendable (borrowing fastdds.LivelinessChangedStatus) -> Void
    public typealias SampleRejectedCallback = @Sendable (borrowing fastdds.SampleRejectedStatus) -> Void
    public typealias IncompatibleQosCallback = @Sendable (borrowing fastdds.RequestedIncompatibleQosStatus) -> Void
    public typealias SampleLostCallback = @Sendable (borrowing fastdds.SampleLostStatus) -> Void

    public let raw: OpaquePointer
    public let subscriber: Subscriber
    public let topic: Topic
    private var callbacks = ReaderCallbacks()
    private let listener: UnsafeMutablePointer<_DataReader.Listener>
    private let mask = Mutex(_StatusMask.data_available())

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
            .init(from: _DataReader.getQos(raw))
        }
        set(newValue) {
            let ret = _DataReader.setQos(raw, newValue.raw)
            assert(ret == fastdds.RETCODE_OK)
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
                var info = _SampleInfo()
                while (withUnsafeMutablePointer(to: &data) { dataPtr in _DataReader.takeNextSample(self.raw, dataPtr, &info) } == 0) {
                    continuation.yield(data)
                }
                callback = { message in
                    continuation.yield(message)
                }
            }
            continuation.onTermination = { _ in
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
        let dataReaderPtr = _DataReader.create(subscriber.raw, .init(profile), topic.raw)
        guard (dataReaderPtr != nil) else {
            return nil
        }
        try self.init(from: dataReaderPtr!, subscriber: subscriber, topic: topic)
    }
    public convenience init?(subscriber: Subscriber, topic: Topic, qos: Qos? = nil) throws {
        let dataReaderPtr = _DataReader.create(subscriber.raw, (qos ?? .getBase(for: subscriber)).raw, topic.raw)
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
            _DataReader.createListener(OpaquePointer(ptr))
        }
        callbacks.setCallbacks {
            // Data Available
            self.messageCallback.withLock { callback in
                guard callback != nil else { return }
                var data = DataType()
                var info = fastdds.SampleInfo()
                while (withUnsafeMutablePointer(to: &data) { dataPtr in _DataReader.takeNextSample(self.raw, dataPtr, &info) } == 0) {
                    callback?(data)
                }
            }
        } onSubscriptionMatched: { statusPtr in
            // Subscription Matched
            let status = UnsafePointer<fastdds.SubscriptionMatchedStatus>(OpaquePointer(statusPtr)).pointee
            self.atomicMatchedWriters.store(status.current_count, ordering: .sequentiallyConsistent)
            self.subscriptionMatchedCallback.withLock { callback in
                callback?(status)
            }
        } onRequestedDeadlineMissed: { statusPtr in
            // Requested Deadline Missed
            self.deadlineMissedCallback.withLock { callback in
                callback?(UnsafePointer<fastdds.DeadlineMissedStatus>(OpaquePointer(statusPtr)).pointee)
            }
        } onLivelinessChanged: { statusPtr in
            // Liveliness Changed
            self.livelinessChangedCallback.withLock { callback in
                callback?(UnsafePointer<fastdds.LivelinessChangedStatus>(OpaquePointer(statusPtr)).pointee)
            }
        } onSampleRejected: { statusPtr in
            // Sample Rejected
            self.sampleRejectedCallback.withLock { callback in
                callback?(UnsafePointer<fastdds.SampleRejectedStatus>(OpaquePointer(statusPtr)).pointee)
            }
        } onRequestedIncompatibleQos: { statusPtr in
            // Requested Incompatible Qos
            self.incompatibleQosCallback.withLock { callback in
                callback?(UnsafePointer<fastdds.IncompatibleQosStatus>(OpaquePointer(statusPtr)).pointee)
            }
        } onSampleLost: { statusPtr in
            // Sample Lost
            self.sampleLostCallback.withLock { callback in
                callback?(UnsafePointer<fastdds.SampleLostStatus>(OpaquePointer(statusPtr)).pointee)
            }
        }
        try setListenerMask()
    }
    deinit {
        let ret = _DataReader.destroy(raw)
        assert(ret == fastdds.RETCODE_OK, "Failed to destroy static DataReader: \(String(describing: DDSError(rawValue: ret)))")

        _DataReader.destroyListener(listener)
    }

    private func setListenerMask() throws {
        try mask.withLock { mask in
            try DDSError.check(code: _DataReader.setListener(raw, listener, mask))
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
            _statusMaskAdd(&mask, _StatusMask.subscription_matched())
        }
        try setListenerMask()
    }
    public func onDeadlineMissed(perform action: @escaping DeadlineMissedCallback) throws {
        deadlineMissedCallback.withLock { callback in
            callback = action
        }
        mask.withLock { mask in
            _statusMaskAdd(&mask, _StatusMask.requested_deadline_missed())
        }
        try setListenerMask()
    }
    public func onLivelinessChanged(perform action: @escaping LivelinessChangedCallback) throws {
        livelinessChangedCallback.withLock { callback in
            callback = action
        }
        mask.withLock { mask in
            _statusMaskAdd(&mask, _StatusMask.liveliness_changed())
        }
        try setListenerMask()
    }
    public func onSampleRejected(perform action: @escaping SampleRejectedCallback) throws {
        sampleRejectedCallback.withLock { callback in
            callback = action
        }
        mask.withLock { mask in
            _statusMaskAdd(&mask, _StatusMask.sample_rejected())
        }
        try setListenerMask()
    }
    public func onIncompatibleQos(perform action: @escaping IncompatibleQosCallback) throws {
        incompatibleQosCallback.withLock { callback in
            callback = action
        }
        mask.withLock { mask in
            _statusMaskAdd(&mask, _StatusMask.requested_incompatible_qos())
        }
        try setListenerMask()
    }
    public func onSampleLost(perform action: @escaping SampleLostCallback) throws {
        sampleLostCallback.withLock { callback in
            callback = action
        }
        mask.withLock { mask in
            _statusMaskAdd(&mask, _StatusMask.sample_lost())
        }
        try setListenerMask()
    }

    public struct Qos: Sendable, Equatable {
        public var raw: _DataReader.DataReaderQos

        @inlinable public static func == (lhs: Qos, rhs: Qos) -> Bool {
            _DataReader.compareQos(lhs.raw, rhs.raw)
        }

        @inlinable public init() {
            self.init(from: _DataReader.DataReaderQos())
        }
        public init(from qos: _DataReader.DataReaderQos) {
            raw = qos
        }

        @inlinable public static func getBase(for subscriber: Subscriber) -> Qos {
            Qos(from: _DataReader.getDefaultQos(subscriber.raw))
        }
    }
}
