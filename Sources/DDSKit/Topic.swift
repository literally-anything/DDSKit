import fastdds
import DDSKitInternal

public final class Topic: @unchecked Sendable {
    public typealias InconsistentTopicCallback = (fastdds.InconsistentTopicStatus) -> Void

    public let raw: OpaquePointer
    public let participant: DomainParticipant
    private var callbacks = TopicCallbacks()
    private let listener: UnsafeMutablePointer<_Topic.Listener>
    private var inconsistentTopicCallback: InconsistentTopicCallback?
    public var qos: Qos {
        get {
            .init(from: _Topic.getQos(raw))
        }
        set(newValue) {
            let ret = _Topic.setQos(raw, newValue.raw)
            assert(ret == fastdds.RETCODE_OK)
        }
    }

    public convenience init?(participant: DomainParticipant, name: String, typeName: String, profile: String) throws {
        let topicPtr = _Topic.create(participant.raw, .init(name), .init(typeName), .init(profile))
        guard (topicPtr != nil) else {
            return nil
        }
        try self.init(from: topicPtr!, participant: participant)
    }
    public convenience init?(participant: DomainParticipant, name: String, typeName: String, qos: Qos? = nil) throws {
        let topicPtr = _Topic.create(participant.raw, .init(name), .init(typeName), (qos ?? .getBase(for: participant)).raw)
        guard (topicPtr != nil) else {
            return nil
        }
        try self.init(from: topicPtr!, participant: participant)
    }
    public init(from topicPtr: OpaquePointer, participant domainParticipant: DomainParticipant) throws {
        raw = topicPtr
        participant = domainParticipant

        listener = withUnsafePointer(to: &callbacks) { ptr in
            _Topic.createListener(OpaquePointer(ptr))
        }
        callbacks.setCallbacks { status in
            self.inconsistentTopicCallback?(UnsafePointer<fastdds.InconsistentTopicStatus>(OpaquePointer(status)).pointee)
        }
        try DDSError.check(code: _Topic.setListener(raw, listener, _StatusMask.inconsistent_topic()))
    }
    deinit {
        let ret = _Topic.destroy(raw)
        assert(ret == fastdds.RETCODE_OK, "Failed to destroy Topic: \(String(describing: DDSError(rawValue: ret)))")

        _Topic.destroyListener(listener)
    }

    public func onInconsistentTopic(perform action: @escaping InconsistentTopicCallback) {
        inconsistentTopicCallback = action
    }

    public struct Qos: Sendable, Equatable {
        public var raw: _Topic.TopicQos

        @inlinable public static func == (lhs: Qos, rhs: Qos) -> Bool {
            _Topic.compareQos(lhs.raw, rhs.raw)
        }

        @inlinable public init() {
            self.init(from: _Topic.TopicQos())
        }
        public init(from qos: _Topic.TopicQos) {
            raw = qos
        }

        @inlinable public static func getBase(for participant: DomainParticipant) -> Qos {
            Qos(from: _Topic.getDefaultQos(participant.raw))
        }
    }
}
