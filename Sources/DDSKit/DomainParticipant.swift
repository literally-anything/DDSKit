import fastdds

public final class DomainParticipant: @unchecked Sendable {
    public let raw: OpaquePointer
    private let listener: UnsafeMutablePointer<_DomainParticipant.Listener>
    public var qos: Qos {
        get {
            .init(from: _DomainParticipant.getQos(raw))
        }
        set(newValue) {
            let ret = _DomainParticipant.setQos(raw, newValue.raw)
            assert(ret == fastdds.RETCODE_OK)
        }
    }

    public convenience init?(domain: _DomainId, profile: String) {
        let participantPtr = _DomainParticipant.create(domain, .init(profile), nil, _StatusMask.none())
        guard (participantPtr != nil) else {
            return nil
        }
        self.init(from: participantPtr!)
    }
    public convenience init?(domain: _DomainId, qos: Qos? = nil) {
        let participantPtr = _DomainParticipant.create(domain, (qos ?? .base).raw, nil, _StatusMask.none())
        guard (participantPtr != nil) else {
            return nil
        }
        self.init(from: participantPtr!)
    }
    public init(from participantPtr: OpaquePointer) {
        raw = participantPtr

        listener = _DomainParticipant.createListener()
        _DomainParticipant.setListenerParticipantDiscoveryCallback(listener) { context, participant, reason, info in
            print("participant discovered")
            return false
        }
        _DomainParticipant.setListenerDataReaderDiscoveryCallback(listener) { context, participant, reason, info in
            print("subscriber discovered")
            return false
        }
        _DomainParticipant.setListenerDataWriterDiscoveryCallback(listener) { context, participant, reason, info in
            print("publisher discovered")
            return false
        }
        _DomainParticipant.setListener(raw, listener)
    }
    deinit {
        let ret = _DomainParticipant.destroy(raw)
        assert(ret == fastdds.RETCODE_OK, "Failed to destroy DomainParticipant: \(ret)")

        _DomainParticipant.destroyListener(listener)
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

// extension DomainParticipant: 
