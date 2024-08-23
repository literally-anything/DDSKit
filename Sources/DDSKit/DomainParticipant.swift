public import enum fastdds.fastdds
import DDSKitInternal
import Synchronization

public final class DomainParticipant: @unchecked Sendable {
    public typealias ParticipantDiscoveredCallback = (OpaquePointer, borrowing fastdds.DDSParticipantDiscoveryStatus, borrowing fastdds.DDSParticipantBuiltinTopicData) -> Void

    public let raw: OpaquePointer
    private var callbacks = ParticipantCallbacks()
    private let listener: UnsafeMutablePointer<fastdds._DomainParticipant.Listener>
    private var participantDiscoveredCallback: ParticipantDiscoveredCallback?

    public var domainId: UInt32 {
        fastdds._DomainParticipant.getDomainId(raw)
    }
    public var qos: Qos {
        get {
            .init(from: fastdds._DomainParticipant.getQos(raw))
        }
        set(newValue) {
            let ret = fastdds._DomainParticipant.setQos(raw, newValue.raw)
            assert(ret == DDSError.OK)
        }
    }

    public convenience init?(domain: fastdds.DDSDomainId, profile: String) throws {
        let participantPtr = fastdds._DomainParticipant.create(domain, .init(profile))
        guard (participantPtr != nil) else {
            return nil
        }
        try self.init(from: participantPtr!)
    }
    public convenience init?(domain: fastdds.DDSDomainId, qos: Qos? = nil) throws {
        let participantPtr = fastdds._DomainParticipant.create(domain, (qos ?? .base).raw)
        guard (participantPtr != nil) else {
            return nil
        }
        try self.init(from: participantPtr!)
    }
    public init(from participantPtr: OpaquePointer) throws {
        raw = participantPtr

        listener = withUnsafePointer(to: &callbacks) { ptr in
            fastdds._DomainParticipant.createListener(OpaquePointer(ptr))
        }
        callbacks.setCallbacks { [unowned self] participant, statusPtr, infoPtr in
            self.participantDiscoveredCallback?(participant,
                                                UnsafePointer<fastdds.DDSParticipantDiscoveryStatus>(OpaquePointer(statusPtr)).pointee,
                                                UnsafePointer<fastdds.DDSParticipantBuiltinTopicData>(OpaquePointer(infoPtr)).pointee)
        }
        try DDSError.check(code: fastdds._DomainParticipant.setListener(raw, listener, fastdds._StatusMask.none()))
    }
    deinit {
        let ret = fastdds._DomainParticipant.destroy(raw)
        assert(ret == DDSError.OK, "Failed to destroy DomainParticipant: \(String(describing: DDSError(rawValue: ret)))")

        fastdds._DomainParticipant.destroyListener(listener)
    }

    public func onParticipantDiscovery(perform action: @escaping ParticipantDiscoveredCallback) {
        participantDiscoveredCallback = action;
    }

    public func registerType(type: fastdds._TypeSupport, name: String) throws {
        try DDSError.check(code: fastdds._DomainParticipant.registerType(raw, type, .init(name)))
    }

    public struct Qos: Sendable, Equatable {
        public var raw: fastdds._DomainParticipant.DomainParticipantQos

        public static func == (lhs: Qos, rhs: Qos) -> Bool {
            fastdds._DomainParticipant.compareQos(lhs.raw, rhs.raw)
        }

        public init() {
            self.init(from: fastdds._DomainParticipant.DomainParticipantQos())
        }
        public init(from qos: fastdds._DomainParticipant.DomainParticipantQos) {
            raw = qos
        }

        public static let base = Qos(from: fastdds._DomainParticipant.getDefaultQos())
    }
}

extension DomainParticipant: CustomStringConvertible {
    public var description: String {
        "DomainParticipant(domainId: \(domainId))"
    }
}
