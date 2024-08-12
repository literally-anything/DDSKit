public struct ReaderCallbacks {
    public typealias DataAvailableCallback = () -> Void
    public typealias SubscriptionMatchedCallback = (UnsafeRawPointer) -> Void
    public typealias RequestedDeadlineMissedCallback = (UnsafeRawPointer) -> Void
    public typealias LivelinessChangedCallback = (UnsafeRawPointer) -> Void
    public typealias SampleRejectedCallback = (UnsafeRawPointer) -> Void
    public typealias RequestedIncompatibleQosCallback = (UnsafeRawPointer) -> Void
    public typealias SampleLostCallback = (UnsafeRawPointer) -> Void

    @usableFromInline internal var onDataAvailable: DataAvailableCallback = { }
    @usableFromInline internal var onSubscriptionMatched: SubscriptionMatchedCallback = { _ in }
    @usableFromInline internal var onRequestedDeadlineMissed: RequestedDeadlineMissedCallback = { _ in }
    @usableFromInline internal var onLivelinessChanged: LivelinessChangedCallback = { _ in }
    @usableFromInline internal var onSampleRejected: SampleRejectedCallback = { _ in }
    @usableFromInline internal var onRequestedIncompatibleQos: RequestedIncompatibleQosCallback = { _ in }
    @usableFromInline internal var onSampleLost: SampleLostCallback = { _ in }

    @inlinable public init() {}

    @inlinable public mutating func setCallbacks(onDataAvailable dataAvailable: @escaping DataAvailableCallback,
                                                 onSubscriptionMatched subscriptionMatched: @escaping SubscriptionMatchedCallback,
                                                 onRequestedDeadlineMissed requestedDeadlineMissed: @escaping RequestedDeadlineMissedCallback,
                                                 onLivelinessChanged livelinessChanged: @escaping LivelinessChangedCallback,
                                                 onSampleRejected sampleRejected: @escaping SampleRejectedCallback,
                                                 onRequestedIncompatibleQos requestedIncompatibleQos: @escaping RequestedIncompatibleQosCallback,
                                                 onSampleLost sampleLost: @escaping SampleLostCallback) {
        onDataAvailable = dataAvailable
        onSubscriptionMatched = subscriptionMatched
        onRequestedDeadlineMissed = requestedDeadlineMissed
        onLivelinessChanged = livelinessChanged
        onSampleRejected = sampleRejected
        onRequestedIncompatibleQos = requestedIncompatibleQos
        onSampleLost = sampleLost
    }

    @inlinable public func dataAvailable() {
        onDataAvailable()
    }
    @inlinable public func subscriptionMatched(_ status: UnsafeRawPointer?) {
        onSubscriptionMatched(status!)
    }
    @inlinable public func requestedDeadlineMissed(_ status: UnsafeRawPointer?) {
        onRequestedDeadlineMissed(status!)
    }
    @inlinable public func livelinessChanged(_ status: UnsafeRawPointer?) {
        onLivelinessChanged(status!)
    }
    @inlinable public func sampleRejected(_ status: UnsafeRawPointer?) {
        onSampleRejected(status!)
    }
    @inlinable public func requestedIncompatibleQos(_ status: UnsafeRawPointer?) {
        onRequestedIncompatibleQos(status!)
    }
    @inlinable public func sampleLost(_ status: UnsafeRawPointer?) {
        onSampleLost(status!)
    }
}
