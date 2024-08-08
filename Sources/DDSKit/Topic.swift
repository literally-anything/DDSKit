import fastdds

public final class Topic {
    public let raw: OpaquePointer
    public let participant: DomainParticipant
    private let listener: UnsafeMutablePointer<_Topic.Listener>
    public var qos: Qos {
        get {
            .init(from: _Topic.getQos(raw))
        }
        set(newValue) {
            let ret = _Topic.setQos(raw, newValue.raw)
            assert(ret == fastdds.RETCODE_OK)
        }
    }

    public convenience init?(participant: DomainParticipant, name: String, typeName: String, profile: String) {
        let topicPtr = _Topic.create(participant.raw, .init(name), .init(typeName), .init(profile))
        guard (topicPtr != nil) else {
            return nil
        }
        self.init(from: topicPtr!, participant: participant)
    }
    public convenience init?(participant: DomainParticipant, name: String, typeName: String, qos: Qos? = nil) {
        let topicPtr = _Topic.create(participant.raw, .init(name), .init(typeName), (qos ?? .getBase(for: participant)).raw)
        guard (topicPtr != nil) else {
            return nil
        }
        self.init(from: topicPtr!, participant: participant)
    }
    public init(from topicPtr: OpaquePointer, participant domainParticipant: DomainParticipant) {
        raw = topicPtr
        participant = domainParticipant

        listener = _Topic.createListener()
        _Topic.setListenerInconsistentTopicCallback(listener) { context, topic, status in
            print("inconsistant topic types. count:", status.total_count)
        }
        _Topic.setListener(raw, listener, _StatusMask.inconsistent_topic())
    }
    deinit {
        let ret = _Topic.destroy(raw)
        assert(ret == fastdds.RETCODE_OK, "Failed to destroy Topic: \(ret)")

        _Topic.destroyListener(listener)
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
