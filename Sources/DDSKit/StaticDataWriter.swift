import fastdds
import DDSKitInternal

public final class StaticDataWriter<DataType: StaticIDLType>: @unchecked Sendable {
    public typealias PublicationMatchedCallback = @Sendable (fastdds.PublicationMatchedStatus) -> Void
    public typealias OfferedDeadlineMissedCallback = @Sendable (fastdds.DeadlineMissedStatus) -> Void
    public typealias OfferedIncompatibleQosCallback = @Sendable (fastdds.IncompatibleQosStatus) -> Void
    public typealias LivelinessLostCallback = @Sendable (fastdds.LivelinessLostStatus) -> Void
    public typealias UnacknowledgedSampleRemovedCallback = @Sendable (fastdds.InstanceHandle_t) -> Void

    public let raw: OpaquePointer
    public let publisher: Publisher
    public let topic: Topic
    private var callbacks = WriterCallbacks()
    private let listener: UnsafeMutablePointer<_DataWriter.Listener>

    private var publicationMatchedCallback: PublicationMatchedCallback?
    private var offeredDeadlineMissedCallback: OfferedDeadlineMissedCallback?
    private var offeredIncompatibleQosCallback: OfferedIncompatibleQosCallback?
    private var livelinessLostCallback: LivelinessLostCallback?
    private var unacknowledgedSampleRemovedCallback: UnacknowledgedSampleRemovedCallback?

    public private(set) var matchedReaders: Int32 = 0
    public var hasReaders: Bool {
        matchedReaders > 0
    }
    nonisolated public var qos: Qos {
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
        guard (dataReaderPtr != nil) else {
            return nil
        }
        try self.init(from: dataReaderPtr!, publisher: publisher, topic: topic)
    }
    public convenience init?(publisher: Publisher, topic: Topic, qos: Qos? = nil) throws {
        let dataReaderPtr = _DataWriter.create(publisher.raw, (qos ?? .getBase(for: publisher)).raw, topic.raw)
        guard (dataReaderPtr != nil) else {
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
            self.publicationMatchedCallback?(UnsafePointer<fastdds.PublicationMatchedStatus>(OpaquePointer(statusPtr)).pointee)
        } onOfferedDeadlineMissed: { statusPtr in
            // Offered Deadline Missed
            self.offeredDeadlineMissedCallback?(UnsafePointer<fastdds.DeadlineMissedStatus>(OpaquePointer(statusPtr)).pointee)
        } onOfferedIncompatibleQos: { statusPtr in
            // Offered Incompatible Qos
            self.offeredIncompatibleQosCallback?(UnsafePointer<fastdds.IncompatibleQosStatus>(OpaquePointer(statusPtr)).pointee)
        } onLivelinessLost: { statusPtr in
            // Liveliness Lost
            self.livelinessLostCallback?(UnsafePointer<fastdds.LivelinessLostStatus>(OpaquePointer(statusPtr)).pointee)
        } onUnacknowledgedSampleRemoved: { handlePtr in
            // Unacknowledged Sample Removed
            self.unacknowledgedSampleRemovedCallback?(UnsafePointer<fastdds.InstanceHandle_t>(OpaquePointer(handlePtr)).pointee)
        }
        var mask = _StatusMask.publication_matched()
        _statusMaskAdd(&mask, _StatusMask.offered_deadline_missed())
        _statusMaskAdd(&mask, _StatusMask.offered_incompatible_qos())
        _statusMaskAdd(&mask, _StatusMask.liveliness_lost())
        let ret = _DataWriter.setListener(raw, listener, mask)
        guard (ret == fastdds.RETCODE_OK) else {
            throw DDSError(rawValue: ret)!
        }
    }
    deinit {
        let ret = _DataWriter.destroy(raw)
        assert(ret == fastdds.RETCODE_OK, "Failed to destroy static DataReader: \(String(describing: DDSError(rawValue: ret)))")

        _DataWriter.destroyListener(listener)
    }

    public func write(message: DataType) throws {
        let ret = withUnsafePointer(to: message) { messagePtr in
            _DataWriter.write(raw, messagePtr, _DataWriter.WriteParams.write_params_default())
        }
        guard (ret == fastdds.RETCODE_OK) else {
            throw DDSError(rawValue: ret)!
        }
    }

    public func onPublicationMatched(perform action: @escaping PublicationMatchedCallback) {
        publicationMatchedCallback = action
    }
    public func onOfferedDeadlineMissed(perform action: @escaping OfferedDeadlineMissedCallback) {
        offeredDeadlineMissedCallback = action
    }
    public func onOfferedIncompatibleQos(perform action: @escaping OfferedIncompatibleQosCallback) {
        offeredIncompatibleQosCallback = action
    }
    public func onLivelinessLost(perform action: @escaping LivelinessLostCallback) {
        livelinessLostCallback = action
    }
    public func onUnacknowledgedSampleRemoved(perform action: @escaping UnacknowledgedSampleRemovedCallback) {
        unacknowledgedSampleRemovedCallback = action
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
