import fastdds

public final class DomainParticipant: @unchecked Sendable {
    public typealias ParticipantDiscoveredCallback = (OpaquePointer, fastrtps.ParticipantDiscoveryStatus, fastdds.ParticipantBuiltinTopicData) -> Bool
    public typealias DataReaderDiscoveredCallback = (OpaquePointer, fastrtps.ReaderDiscoveryStatus, fastdds.SubscriptionBuiltinTopicData) -> Bool
    public typealias DataWriterDiscoveredCallback = (OpaquePointer, fastrtps.WriterDiscoveryStatus, fastdds.PublicationBuiltinTopicData) -> Bool

    public let raw: OpaquePointer
    private let listener: UnsafeMutablePointer<_DomainParticipant.Listener>
    private var participantDiscoveredCallback: ParticipantDiscoveredCallback = { _, _, _ in return false }
    private var dataReaderDiscoveredCallback: DataReaderDiscoveredCallback = { _, _, _ in return false }
    private var dataWriterDiscoveredCallback: DataWriterDiscoveredCallback = { _, _, _ in return false }
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

    public convenience init?(domain: _DomainId, profile: String) {
        let participantPtr = _DomainParticipant.create(domain, .init(profile))
        guard (participantPtr != nil) else {
            return nil
        }
        self.init(from: participantPtr!)
    }
    public convenience init?(domain: _DomainId, qos: Qos? = nil) {
        let participantPtr = _DomainParticipant.create(domain, (qos ?? .base).raw)
        guard (participantPtr != nil) else {
            return nil
        }
        self.init(from: participantPtr!)
    }
    public init(from participantPtr: OpaquePointer) {
        raw = participantPtr

        listener = _DomainParticipant.createListener {contextPtr, participant, reason, info in
            guard (contextPtr != nil) else {
                return false
            }
            let context = Unmanaged<DomainParticipant>.fromOpaque(contextPtr!).takeUnretainedValue()
            return context.participantDiscoveredCallback(participant!, reason, info.pointee)
        } _: { contextPtr, participant, reason, info in
            guard (contextPtr != nil) else {
                return false
            }
            let context = Unmanaged<DomainParticipant>.fromOpaque(contextPtr!).takeUnretainedValue()
            return context.dataReaderDiscoveredCallback(participant!, reason, info.pointee)
        } _: { contextPtr, participant, reason, info in
            guard (contextPtr != nil) else {
                return false
            }
            let context = Unmanaged<DomainParticipant>.fromOpaque(contextPtr!).takeUnretainedValue()
            return context.dataWriterDiscoveredCallback(participant!, reason, info.pointee)
        }
        _DomainParticipant.setListenerContext(listener, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        _DomainParticipant.setListener(raw, listener, _StatusMask.none())
    }
    deinit {
        _DomainParticipant.setListenerContext(listener, nil)

        let ret = _DomainParticipant.destroy(raw)
        assert(ret == fastdds.RETCODE_OK, "Failed to destroy DomainParticipant: \(ret)")

        _DomainParticipant.destroyListener(listener)
    }

    public func onParticipantDiscovery(perform action: @escaping ParticipantDiscoveredCallback) {
        participantDiscoveredCallback = action;
    }
    public func onReaderDiscovery(perform action: @escaping DataReaderDiscoveredCallback) {
        dataReaderDiscoveredCallback = action;
    }
    public func onWriterDiscovery(perform action: @escaping DataWriterDiscoveredCallback) {
        dataWriterDiscoveredCallback = action;
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
