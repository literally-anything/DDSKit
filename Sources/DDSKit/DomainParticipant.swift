import fastdds
import DDSKitInternal
import Synchronization

public final class DomainParticipant: @unchecked Sendable {
    public typealias ParticipantDiscoveredCallback = (OpaquePointer, borrowing fastrtps.ParticipantDiscoveryStatus, borrowing fastdds.ParticipantBuiltinTopicData) -> Void

    public let raw: OpaquePointer
    private var callbacks = ParticipantCallbacks()
    private let listener: UnsafeMutablePointer<_DomainParticipant.Listener>
    private var participantDiscoveredCallback: ParticipantDiscoveredCallback?

    public var domainId: UInt32 {
        _DomainParticipant.getDomainId(raw)
    }
    public var qos: Qos {
        get {
            .init(from: _DomainParticipant.getQos(raw))
        }
        set(newValue) {
            let ret = _DomainParticipant.setQos(raw, newValue.raw)
            assert(ret == fastdds.RETCODE_OK)
        }
    }

    public convenience init?(domain: _DomainId, profile: String) throws {
        let participantPtr = _DomainParticipant.create(domain, .init(profile))
        guard (participantPtr != nil) else {
            return nil
        }
        try self.init(from: participantPtr!)
    }
    public convenience init?(domain: _DomainId, qos: Qos? = nil) throws {
        let participantPtr = _DomainParticipant.create(domain, (qos ?? .base).raw)
        guard (participantPtr != nil) else {
            return nil
        }
        try self.init(from: participantPtr!)
    }
    public init(from participantPtr: OpaquePointer) throws {
        raw = participantPtr

        listener = withUnsafePointer(to: &callbacks) { ptr in
            _DomainParticipant.createListener(OpaquePointer(ptr))
        }
        callbacks.setCallbacks { [unowned self] participant, statusPtr, infoPtr in
            self.participantDiscoveredCallback?(participant,
                                                UnsafePointer<fastrtps.ParticipantDiscoveryStatus>(OpaquePointer(statusPtr)).pointee,
                                                UnsafePointer<fastdds.ParticipantBuiltinTopicData>(OpaquePointer(infoPtr)).pointee)
        }
        try DDSError.check(code: _DomainParticipant.setListener(raw, listener, _StatusMask.none()))
    }
    deinit {
        let ret = _DomainParticipant.destroy(raw)
        assert(ret == fastdds.RETCODE_OK, "Failed to destroy DomainParticipant: \(String(describing: DDSError(rawValue: ret)))")

        _DomainParticipant.destroyListener(listener)
    }

    public func onParticipantDiscovery(perform action: @escaping ParticipantDiscoveredCallback) {
        participantDiscoveredCallback = action;
    }

    public func registerType(type: _TypeSupport, name: String) throws {
        try DDSError.check(code: _DomainParticipant.registerType(raw, type, .init(name)))
    }

    public struct Qos: Sendable, Equatable {
        public var raw: _DomainParticipant.DomainParticipantQos

        @inlinable public static func == (lhs: Qos, rhs: Qos) -> Bool {
            _DomainParticipant.compareQos(lhs.raw, rhs.raw)
        }

        @inlinable public init() {
            self.init(from: _DomainParticipant.DomainParticipantQos())
        }
        public init(from qos: _DomainParticipant.DomainParticipantQos) {
            raw = qos
        }

        public static let base = Qos(from: _DomainParticipant.getDefaultQos())
    }
}

extension DomainParticipant: CustomStringConvertible {
    public var description: String {
        "DomainParticipant(domainId: \(domainId))"
    }
}
