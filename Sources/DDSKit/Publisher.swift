import fastdds

open class Publisher: @unchecked Sendable {
    public let raw: OpaquePointer
    public let participant: DomainParticipant
    public var qos: Qos {
        get {
            .init(from: fastdds._Publisher.getQos(raw))
        }
        set(newValue) {
            let ret = fastdds._Publisher.setQos(raw, newValue.raw)
            assert(ret == DDSError.OK)
        }
    }

    public convenience init?(participant: DomainParticipant, profile: String) {
        let publisherPtr = fastdds._Publisher.create(participant.raw, .init(profile))
        guard (publisherPtr != nil) else {
            return nil
        }
        self.init(from: publisherPtr!, participant: participant)
    }
    public convenience init?(participant: DomainParticipant, qos: Qos? = nil) {
        let publisherPtr = fastdds._Publisher.create(participant.raw, (qos ?? .getBase(for: participant)).raw)
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
        let ret = fastdds._Publisher.destroy(raw)
        assert(ret == DDSError.OK, "Failed to destroy Publisher: \(String(describing: DDSError(rawValue: ret)))")
    }

    public struct Qos: Sendable, Equatable {
        public var raw: fastdds._Publisher.PublisherQos

        @inlinable public static func == (lhs: Qos, rhs: Qos) -> Bool {
            fastdds._Publisher.compareQos(lhs.raw, rhs.raw)
        }

        @inlinable public init() {
            self.init(from: fastdds._Publisher.PublisherQos())
        }
        public init(from qos: fastdds._Publisher.PublisherQos) {
            raw = qos
        }

        @inlinable public static func getBase(for participant: DomainParticipant) -> Qos {
            Qos(from: fastdds._Publisher.getDefaultQos(participant.raw))
        }
    }
}
