/**
 * Topic.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/05/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

// extension Topic: DestroyableEntity {}

/// A topic for a message.
/// 
/// A topic represents the abstract idea of the single data flow from a Publisher to a Subscriber.
/// Topics have a name and a type, and they only match with other topics that have the same name and type.
public final class DDSTopic<Message: CDRCodable> : @unchecked Sendable {
    /// The participant that this topic is associated with.
    public let participant: DDSParticipant
    /// A wrapper around the underlying FastDDS Topic.
    /// The wrapper is needed because the FastDDS Topic is mostly virtual and fails to import into swift.
    internal var raw: FastDDS.Topic

    /// Creates a new topic.
    /// - Parameters:
    ///   - participant: The participant to use for the topic.
    ///   - topic: The name of the topic.
    /// - Throws: If the topic cannot be created.
    public init(participant: DDSParticipant, topic: String) throws(DDSError) {
        self.participant = participant

        do {
            try participant.registerType(Message.self)
        } catch {
            throw .dataTypeError(error)
        }

        var success = false
        raw = FastDDS.Topic(
            participant: participant.raw,
            topic: .init(topic), typeSupport: Message.ddsTopicType.typeSupport,
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

extension DDSParticipant {
    /// Creates a new topic.
    /// - Parameters:
    ///   - name: The name of the topic.
    ///   - type: The message data type of the topic.
    /// - Throws: If the topic cannot be created.
    /// - Returns: The new topic.
    @inlinable
    public func getTopic<T: CDRCodable>(named name: String, type: T.Type) throws(DDSError) -> DDSTopic<T> {
        try DDSTopic<T>(participant: self, topic: name)
    }
}
