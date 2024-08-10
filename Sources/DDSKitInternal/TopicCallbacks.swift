public struct TopicCallbacks: Sendable {
    public typealias InconsistentTopicCallback = @Sendable (UnsafeRawPointer) -> Void

    @usableFromInline internal var onInconsistentTopic: InconsistentTopicCallback = { status in }

    @inlinable public init() {}

    @inlinable public mutating func setCallbacks(onInconsistentTopic inconsistentTopic: @escaping InconsistentTopicCallback) {
        onInconsistentTopic = inconsistentTopic
    }

    @inlinable public func inconsistentTopic(_ status: UnsafeRawPointer) {
        onInconsistentTopic(status)
    }
}
