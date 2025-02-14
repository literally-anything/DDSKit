/**
 * Topic.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/05/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS
internal import _FastDDSHelpers

// extension Topic: DestroyableEntity {}

public final class DDSTopic<T: CDRCodable>: @unchecked Sendable {
    public let participant: DDSParticipant
    internal var raw: Topic
    private var callbacks = TopicCallbacks()

    public init(participant: DDSParticipant, topic: String) throws(DDSError) {
        self.participant = participant

        do {
            try participant.registerType(T.self)
        } catch {
            throw .dataTypeError(error)
        }

        var success = false
        raw = withUnsafeMutablePointer(to: &callbacks) { callbacksPtr in
            Topic(
                participant: participant.raw,
                topic: .init(topic), typeSupport: T.ddsTopicType.typeSupport,
                profile: Topic.getDefaultQos(participant: participant.raw),
                callbacks: .init(callbacksPtr), statusMask: [],
                success: &success
            )
        }
        if !success {
            throw DDSError.initializationError(from: .topic)
        }
    }

    deinit {
        let ret = FastDDSErrorCode.check(raw.destroy())
        if let ret {
            let error = DDSError.destructionError(
                from: .topic,
                ret
            )
            fatalError("\(error)")
        }
    }

    public var name: String {
        .init(raw.name)
    }

    public var typeName: String {
        .init(raw.typeName)
    }
}

extension DDSTopic: CustomStringConvertible {
    public var description: String {
        "DDSTopic(name: \(name), type: \(typeName))"
    }
}
