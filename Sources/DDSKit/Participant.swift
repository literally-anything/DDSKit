/**
 * DomainParticipant.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/03/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS
internal import _FastDDSHelpers

public final class DDSParticipant: @unchecked Sendable {
    internal let raw: Participant
    private var callbacks = ParticipantCallbacks()

    public init() {
        raw = withUnsafePointer(to: callbacks) { callbacksPtr in
            Participant(callbacks: .init(callbacksPtr))
        }
    }

    public init(domain: UInt32, profile: String) {
        raw = withUnsafePointer(to: callbacks) { callbacksPtr in
            Participant(domain: domain, profile: .init(profile), callbacks: .init(callbacksPtr), statusMask: [])
        }
    }

    public init(domain: UInt32, qos: Qos) {
        raw = withUnsafePointer(to: callbacks) { callbacksPtr in
            Participant(domain: domain, profile: qos.raw, callbacks: .init(callbacksPtr), statusMask: [])
        }
    }
    
    public var domain: UInt32 {
        raw.domain
    }
}

extension DDSParticipant {
    public struct Qos: Sendable, Equatable {
        internal var raw: Participant.DomainParticipantQos

        public static func == (lhs: Qos, rhs: Qos) -> Bool {
            Participant.compareQos(lhs.raw, rhs.raw)
        }

        public static let base = Qos(raw: Participant.getDefaultQos())
    }
}

extension DDSParticipant: CustomStringConvertible {
    public var description: String {
        "DDSParticipant(domain: \(domain))"
    }
}
