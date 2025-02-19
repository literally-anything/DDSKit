/**
 * Topic.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/05/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

// extension Topic: DestroyableEntity {}

public final class DDSTopic<T: CDRCodable> : @unchecked Sendable {
    public let participant: DDSParticipant
    internal var raw: FastDDS.Topic

    public init(participant: DDSParticipant, topic: String) throws(DDSError) {
        self.participant = participant

        do {
            try participant.registerType(T.self)
        } catch {
            throw .dataTypeError(error)
        }

        var success = false
        raw = FastDDS.Topic(
            participant: participant.raw,
            topic: .init(topic), typeSupport: T.ddsTopicType.typeSupport,
            // profile: FastDDS.Topic.Qos(participant: participant.raw),
            success: &success
        )
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

    /// The name of the topic.
    public var name: String {
        .init(raw.name)
    }

    /// The type name of the topic.
    public var typeName: String {
        .init(raw.typeName)
    }
}

extension DDSTopic: CustomStringConvertible {
    public var description: String {
        "DDSTopic(name: \(name), type: \(typeName))"
    }
}
