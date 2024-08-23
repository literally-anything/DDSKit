import fastdds

open class Subscriber: @unchecked Sendable {
    public let raw: OpaquePointer
    public let participant: DomainParticipant
    public var qos: Qos {
        get {
            .init(from: fastdds._Subscriber.getQos(raw))
        }
        set(newValue) {
            let ret = fastdds._Subscriber.setQos(raw, newValue.raw)
            assert(ret == DDSError.OK)
        }
    }

    public convenience init?(participant: DomainParticipant, profile: String) {
        let subscriberPtr = fastdds._Subscriber.create(participant.raw, .init(profile))
        guard (subscriberPtr != nil) else {
            return nil
        }
        self.init(from: subscriberPtr!, participant: participant)
    }
    public convenience init?(participant: DomainParticipant, qos: Qos? = nil) {
        let subscriberPtr = fastdds._Subscriber.create(participant.raw, (qos ?? .getBase(for: participant)).raw)
        guard (subscriberPtr != nil) else {
            return nil
        }
        self.init(from: subscriberPtr!, participant: participant)
    }
    public init(from subscriberPtr: OpaquePointer, participant domainParticipant: DomainParticipant) {
        raw = subscriberPtr
        participant = domainParticipant
    }
    deinit {
        let ret = fastdds._Subscriber.destroy(raw)
        assert(ret == DDSError.OK, "Failed to destroy Subscriber: \(String(describing: DDSError(rawValue: ret)))")
    }

    public struct Qos: Sendable, Equatable {
        public var raw: fastdds._Subscriber.SubscriberQos

        @inlinable public static func == (lhs: Qos, rhs: Qos) -> Bool {
            fastdds._Subscriber.compareQos(lhs.raw, rhs.raw)
        }

        @inlinable public init() {
            self.init(from: fastdds._Subscriber.SubscriberQos())
        }
        public init(from qos: fastdds._Subscriber.SubscriberQos) {
            raw = qos
        }

        @inlinable public static func getBase(for participant: DomainParticipant) -> Qos {
            Qos(from: fastdds._Subscriber.getDefaultQos(participant.raw))
        }
    }
}
