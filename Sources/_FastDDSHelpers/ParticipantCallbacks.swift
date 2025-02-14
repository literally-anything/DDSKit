/**
 * ParticipantCallbacks.swift
 * _FastDDSHelpers
 * 
 * Created by Hunter Baker on 8/09/2024
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */

/// A structure to hold all of the callbacks for a FastDDS DomainParticipantListener.
/// This only needs to exist to allow full swift escaping closures to be passed to the C++ layer without loosing context with @convention(c).
/// This may be replaced with clang blocks in the future or it may be moved into the _CFastDDS target with less OpaquePointers when swiftpm gets mixed-language target support.
/// The functions only exist because, currently, C++ cannot directly call swift closures.
public struct ParticipantCallbacks: Sendable {
    public typealias ParticipantDiscoveredCallback = @Sendable (OpaquePointer, UnsafeRawPointer, UnsafeRawPointer) -> Void

    @usableFromInline
    internal var onParticipantDiscovered: ParticipantDiscoveredCallback? = nil

    @inlinable
    @inline(__always)
    public init() {}

    @inlinable
    @inline(__always)
    public mutating func setCallbacks(onParticipantDiscovered participantDiscovered: ParticipantDiscoveredCallback?) {
        onParticipantDiscovered = participantDiscovered
    }

    @inlinable
    @inline(__always)
    public func participantDiscovered(_ participant: OpaquePointer, _ status: UnsafeRawPointer, _ info: UnsafeRawPointer) {
        onParticipantDiscovered?(participant, status, info)
    }
}
