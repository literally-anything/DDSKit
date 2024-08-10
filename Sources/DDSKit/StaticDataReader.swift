import fastdds
import DDSKitInternal

public final class StaticDataReader<DataType: StaticIDLType>: @unchecked Sendable {
    public typealias MessageCallback = (DataType) -> Void
    public typealias SubscriptionMatchedCallback = (fastdds.SubscriptionMatchedStatus) -> Void
    public typealias DeadlineMissedCallback = (fastdds.RequestedDeadlineMissedStatus) -> Void
    public typealias LivelinessChangedCallback = (fastdds.LivelinessChangedStatus) -> Void
    public typealias SampleRejectedCallback = (fastdds.SampleRejectedStatus) -> Void
    public typealias IncompatibleQosCallback = (fastdds.RequestedIncompatibleQosStatus) -> Void
    public typealias SampleLostCallback = (fastdds.SampleLostStatus) -> Void

    public let raw: OpaquePointer
    public let subscriber: Subscriber
    public let topic: Topic
    private var callbacks = ReaderCallbacks()
    private let listener: UnsafeMutablePointer<_DataReader.Listener>

    private var messageCallback: MessageCallback?
    private var firstMessageCallback: MessageCallback?
    private var subscriptionMatchedCallback: SubscriptionMatchedCallback?
    private var deadlineMissedCallback: DeadlineMissedCallback?
    private var livelinessChangedCallback: LivelinessChangedCallback?
    private var sampleRejectedCallback: SampleRejectedCallback?
    private var incompatibleQosCallback: IncompatibleQosCallback?
    private var sampleLostCallback: SampleLostCallback?

    public private(set) var hasRecievedMessage: Bool = false
    public private(set) var matchedWriters: Int32 = 0
    public var hasWriters: Bool {
        matchedWriters > 0
    }
    nonisolated public var qos: Qos {
        get {
            .init(from: _DataReader.getQos(raw))
        }
        set(newValue) {
            let ret = _DataReader.setQos(raw, newValue.raw)
            assert(ret == fastdds.RETCODE_OK)
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
            guard (self.messageCallback != nil) else { return }
            var data = DataType()
            var info = fastdds.SampleInfo()
            while (withUnsafeMutablePointer(to: &data) { dataPtr in _DataReader.takeNextSample(self.raw, dataPtr, &info) } == 0) {
                if (!self.hasRecievedMessage) {
                    self.hasRecievedMessage = true
                    self.firstMessageCallback?(data)
                }
                self.messageCallback?(data)
            }
        } onSubscriptionMatched: { statusPtr in
            // Subscription Matched
            let status = UnsafePointer<fastdds.SubscriptionMatchedStatus>(OpaquePointer(statusPtr)).pointee
            self.matchedWriters = status.current_count
            self.subscriptionMatchedCallback?(status)
        } onRequestedDeadlineMissed: { statusPtr in
            // Requested Deadline Missed
            self.deadlineMissedCallback?(UnsafePointer<fastdds.DeadlineMissedStatus>(OpaquePointer(statusPtr)).pointee)
        } onLivelinessChanged: { statusPtr in
            // Liveliness Changed
            self.livelinessChangedCallback?(UnsafePointer<fastdds.LivelinessChangedStatus>(OpaquePointer(statusPtr)).pointee)
        } onSampleRejected: { statusPtr in
            // Sample Rejected
            self.sampleRejectedCallback?(UnsafePointer<fastdds.SampleRejectedStatus>(OpaquePointer(statusPtr)).pointee)
        } onRequestedIncompatibleQos: { statusPtr in
            // Requested Incompatible Qos
            self.incompatibleQosCallback?(UnsafePointer<fastdds.IncompatibleQosStatus>(OpaquePointer(statusPtr)).pointee)
        } onSampleLost: { statusPtr in
            // Sample Lost
            self.sampleLostCallback?(UnsafePointer<fastdds.SampleLostStatus>(OpaquePointer(statusPtr)).pointee)
        }
        var mask = _StatusMask.data_available()
        _statusMaskAdd(&mask, _StatusMask.subscription_matched())
        _statusMaskAdd(&mask, _StatusMask.requested_deadline_missed())
        _statusMaskAdd(&mask, _StatusMask.liveliness_changed())
        _statusMaskAdd(&mask, _StatusMask.sample_rejected())
        _statusMaskAdd(&mask, _StatusMask.requested_incompatible_qos())
        _statusMaskAdd(&mask, _StatusMask.sample_lost())
        let ret = _DataReader.setListener(raw, listener, mask)
        guard (ret == fastdds.RETCODE_OK) else {
            throw DDSError(rawValue: ret)!
        }
    }
    deinit {
        let ret = _DataReader.destroy(raw)
        assert(ret == fastdds.RETCODE_OK, "Failed to destroy static DataReader: \(String(describing: DDSError(rawValue: ret)))")

        _DataReader.destroyListener(listener)
    }

    public func onMessage(perform action: @escaping MessageCallback) {
        messageCallback = action
    }
    public func onFirstMessage(perform action: @escaping MessageCallback) {
        firstMessageCallback = action
    }
    public func onSubscriptionMatched(perform action: @escaping SubscriptionMatchedCallback) {
        subscriptionMatchedCallback = action
    }
    public func onDeadlineMissed(perform action: @escaping DeadlineMissedCallback) {
        deadlineMissedCallback = action
    }
    public func onLivelinessChanged(perform action: @escaping LivelinessChangedCallback) {
        livelinessChangedCallback = action
    }
    public func onSampleRejected(perform action: @escaping SampleRejectedCallback) {
        sampleRejectedCallback = action
    }
    public func onIncompatibleQos(perform action: @escaping IncompatibleQosCallback) {
        incompatibleQosCallback = action
    }
    public func onSampleLost(perform action: @escaping SampleLostCallback) {
        sampleLostCallback = action
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
