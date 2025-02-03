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

    init() {
        raw = withUnsafePointer(to: callbacks) { callbacksPtr in
            Participant.init(domain: 0, profile: "", callbacks: .init(callbacksPtr), statusMask: StatusMask.all())
        }
    }
    
    public var domain: UInt32 {
        raw.domain
    }
}

extension DDSParticipant: CustomStringConvertible {
    public var description: String {
        "DDSParticipant(domain: \(domain))"
    }
}
