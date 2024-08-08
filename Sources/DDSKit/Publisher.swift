import fastdds

public class Publisher: @unchecked Sendable {
    public let raw: OpaquePointer
    public let participant: DomainParticipant
    public var qos: Qos {
        get {
            .init(from: _Publisher.getQos(raw))
        }
        set(newValue) {
            let ret = _Publisher.setQos(raw, newValue.raw)
            assert(ret == fastdds.RETCODE_OK)
        }
    }

    public convenience init?(participant: DomainParticipant, profile: String) {
        let publisherPtr = _Publisher.create(participant.raw, .init(profile))
        guard (publisherPtr != nil) else {
            return nil
        }
        self.init(from: publisherPtr!, participant: participant)
    }
    public convenience init?(participant: DomainParticipant, qos: Qos? = nil) {
        let publisherPtr = _Publisher.create(participant.raw, (qos ?? .getBase(for: participant)).raw)
        guard (publisherPtr != nil) else {
            return nil
        }
        self.init(from: publisherPtr!, participant: participant)
    }
    public init(from publisherPtr: OpaquePointer, participant domainParticipant: DomainParticipant) {
        raw = publisherPtr
        participant = domainParticipant
    }
    deinit {
        let ret = _Publisher.destroy(raw)
        assert(ret == fastdds.RETCODE_OK, "Failed to destroy Publisher: \(ret)")
    }

    public struct Qos: Sendable, Equatable {
        public var raw: _Publisher.PublisherQos

        @inlinable public static func == (lhs: Qos, rhs: Qos) -> Bool {
            _Publisher.compareQos(lhs.raw, rhs.raw)
        }

        @inlinable public init() {
            self.init(from: _Publisher.PublisherQos())
        }

        public init(from qos: _Publisher.PublisherQos) {
            raw = qos
        }

        @inlinable public static func getBase(for participant: DomainParticipant) -> Qos {
            Qos(from: _Publisher.getDefaultQos(participant.raw))
        }
    }
}
