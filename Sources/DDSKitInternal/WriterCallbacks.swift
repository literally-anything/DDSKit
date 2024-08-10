public struct WriterCallbacks: Sendable {
    public typealias PublicationMatchedCallback = @Sendable (UnsafeRawPointer) -> Void
    public typealias OfferedDeadlineMissedCallback = @Sendable (UnsafeRawPointer) -> Void
    public typealias OfferedIncompatibleQosCallback = @Sendable (UnsafeRawPointer) -> Void
    public typealias LivelinessLostCallback = @Sendable (UnsafeRawPointer) -> Void
    public typealias UnacknowledgedSampleRemovedCallback = @Sendable (UnsafeRawPointer) -> Void

    @usableFromInline internal var onPublicationMatched: PublicationMatchedCallback = { _ in }
    @usableFromInline internal var onOfferedDeadlineMissed: OfferedDeadlineMissedCallback = { _ in }
    @usableFromInline internal var onOfferedIncompatibleQos: OfferedIncompatibleQosCallback = { _ in }
    @usableFromInline internal var onLivelinessLost: LivelinessLostCallback = { _ in }
    @usableFromInline internal var onUnacknowledgedSampleRemoved: UnacknowledgedSampleRemovedCallback = { _ in }

    @inlinable public init() {}

    @inlinable public mutating func setCallbacks(onPublicationMatched publicationMatched: @escaping PublicationMatchedCallback,
                                                 onOfferedDeadlineMissed offeredDeadlineMissed: @escaping OfferedDeadlineMissedCallback,
                                                 onOfferedIncompatibleQos offeredIncompatibleQos: @escaping OfferedIncompatibleQosCallback,
                                                 onLivelinessLost livelinessLost: @escaping LivelinessLostCallback,
                                                 onUnacknowledgedSampleRemoved unacknowledgedSampleRemoved: @escaping UnacknowledgedSampleRemovedCallback) {
        onPublicationMatched = publicationMatched
        onOfferedDeadlineMissed = offeredDeadlineMissed
        onOfferedIncompatibleQos = offeredIncompatibleQos
        onLivelinessLost = livelinessLost
        onUnacknowledgedSampleRemoved = unacknowledgedSampleRemoved
    }

    @inlinable public func publicationMatched(_ status: UnsafeRawPointer?) {
        onPublicationMatched(status!)
    }
    @inlinable public func offeredDeadlineMissed(_ status: UnsafeRawPointer?) {
        onOfferedDeadlineMissed(status!)
    }
    @inlinable public func offeredIncompatibleQos(_ status: UnsafeRawPointer?) {
        onOfferedIncompatibleQos(status!)
    }
    @inlinable public func livelinessLost(_ status: UnsafeRawPointer?) {
        onLivelinessLost(status!)
    }
    @inlinable public func unacknowledgedSampleRemoved(_ status: UnsafeRawPointer?) {
        onUnacknowledgedSampleRemoved(status!)
    }
}
