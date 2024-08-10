public struct ParticipantCallbacks: Sendable {
    public typealias ParticipantDiscoveredCallback = @Sendable (OpaquePointer, UnsafeRawPointer, UnsafeRawPointer) -> Void

    @usableFromInline internal var onParticipantDiscovered: ParticipantDiscoveredCallback = { participant, status, info in }

    @inlinable public init() {}

    @inlinable public mutating func setCallbacks(onParticipantDiscovered participantDiscovered: @escaping ParticipantDiscoveredCallback) {
        onParticipantDiscovered = participantDiscovered
    }

    @inlinable public func participantDiscovered(_ participant: OpaquePointer, _ status: UnsafeRawPointer, _ info: UnsafeRawPointer) {
        onParticipantDiscovered(participant, status, info)
    }
}
