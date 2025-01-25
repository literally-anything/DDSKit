/**
 * ParticipantCallbacks.swift
 * _FastDDSHelpers
 * 
 * Created by Hunter Baker on 8/09/2024
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
public struct ParticipantCallbacks: Sendable {
    public typealias ParticipantDiscoveredCallback = @Sendable (OpaquePointer, UnsafeRawPointer, UnsafeRawPointer) -> Void

    @usableFromInline
    internal var onParticipantDiscovered: ParticipantDiscoveredCallback = { participant, status, info in }

    @inlinable
    @inline(__always)
    public init() {}

    @inlinable
    @inline(__always)
    public mutating func setCallbacks(onParticipantDiscovered participantDiscovered: @escaping ParticipantDiscoveredCallback) {
        onParticipantDiscovered = participantDiscovered
    }

    @inlinable
    @inline(__always)
    public func participantDiscovered(_ participant: OpaquePointer, _ status: UnsafeRawPointer, _ info: UnsafeRawPointer) {
        onParticipantDiscovered(participant, status, info)
    }
}
