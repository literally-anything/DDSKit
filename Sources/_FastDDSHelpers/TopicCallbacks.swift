/**
 * TopicCallbacks.swift
 * _FastDDSHelpers
 * 
 * Created by Hunter Baker on 8/09/2024
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
public struct TopicCallbacks: Sendable {
    public typealias InconsistentTopicCallback = @Sendable (UnsafeRawPointer) -> Void

    @usableFromInline internal var onInconsistentTopic: InconsistentTopicCallback = { status in }

    @inlinable
    @inline(__always)
    public init() {}

    @inlinable
    @inline(__always)
    public mutating func setCallbacks(onInconsistentTopic inconsistentTopic: @escaping InconsistentTopicCallback) {
        onInconsistentTopic = inconsistentTopic
    }

    @inlinable
    @inline(__always)
    public func inconsistentTopic(_ status: UnsafeRawPointer) {
        onInconsistentTopic(status)
    }
}
