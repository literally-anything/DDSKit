/**
 * WriterCallbacks.swift
 * _FastDDSHelpers
 * 
 * Created by Hunter Baker on 8/09/2024
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
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

    @inlinable
    @inline(__always)
    public init() {}

    @inlinable
    @inline(__always)
    public mutating func setCallbacks(onPublicationMatched publicationMatched: @escaping PublicationMatchedCallback,
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

    @inlinable
    @inline(__always)
    public func publicationMatched(_ status: UnsafeRawPointer?) {
        onPublicationMatched(status!)
    }
    @inlinable
    @inline(__always)
    public func offeredDeadlineMissed(_ status: UnsafeRawPointer?) {
        onOfferedDeadlineMissed(status!)
    }
    @inlinable
    @inline(__always)
    public func offeredIncompatibleQos(_ status: UnsafeRawPointer?) {
        onOfferedIncompatibleQos(status!)
    }
    @inlinable
    @inline(__always)
    public func livelinessLost(_ status: UnsafeRawPointer?) {
        onLivelinessLost(status!)
    }
    @inlinable
    @inline(__always)
    public func unacknowledgedSampleRemoved(_ status: UnsafeRawPointer?) {
        onUnacknowledgedSampleRemoved(status!)
    }
}
