/**
 * Topic.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/05/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

/// A topic for a message.
/// 
/// A topic represents the abstract idea of the single data flow from a Publisher to a Subscriber.
/// Topics have a name and a type, and they only match with other topics that have the same name and type.
public final class DDSTopic<Message: DDSMessage> : @unchecked Sendable {
    /// The participant that this topic is associated with.
    public let participant: DDSParticipant
    /// A wrapper around the underlying FastDDS Topic.
    /// The wrapper is needed because the FastDDS Topic is mostly virtual and fails to import into swift.
    internal var raw: FastDDS.Topic

    /// Creates a new topic.
    /// - Parameters:
    ///   - participant: The participant to use for the topic.
    ///   - topic: The name of the topic.
    ///   - convention: The naming convention to use for the topic. Default is `.default`.
    /// - Throws: If the topic cannot be created.
    @inlinable
    public convenience init(participant: DDSParticipant, topic: String, convention: DDSNamespace.NamingConvention = .default) throws(DDSError) {
        try self.init(participant: participant, topic: topic, typeSupport: Message.ddsTypeSupport, nameInfo: (.topic, convention))
    }

    /// Creates a new topic.
    /// This encapsulates all the internal details of creating a topic.
    /// - Parameters:
    ///   - participant: The participant to use for the topic.
    ///   - topic: The name of the topic.
    ///   - typeSupport: The type support object for the topic.
    ///   - nameInfo: The name type and naming convention of the topic.
    /// - Throws: If the topic cannot be created.
    @usableFromInline
    internal init(
        participant: DDSParticipant, topic: String, typeSupport: borrowing DDSTypeSupport,
        nameInfo: (type: DDSNamespace.NameType, convention: DDSNamespace.NamingConvention)
    ) throws(DDSError) {
        self.participant = participant

        do {
            try participant.registerType(typeSupport: typeSupport)
        } catch {
            throw .dataTypeError(error)
        }

        let qualifiedName = DDSNamespace.current.appending(relative: topic).getName(type: nameInfo.type, convention: nameInfo.convention)

        var ret: Int32 = 0
        raw = FastDDS.Topic(
            participant: participant.raw,
            topic: .init(qualifiedName), typeSupport: typeSupport.typeSupport,
            // profile: FastDDS.Topic.Qos(participant: participant.raw),
            ret: &ret
        )
        if let error = FastDDSErrorCode.check(ret) {
            switch error {
                case .preconditionFailed:
                    throw .typeMismatch(topic: topic, type: .init(typeSupport.typeSupport.name), existingType: .init(raw.typeName))
                default:
                    throw .initializationError(from: .topic)
            }
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

extension DDSTopic: Equatable {
    public static func == (lhs: DDSTopic<Message>, rhs: DDSTopic<Message>) -> Bool {
        lhs.participant === rhs.participant && lhs.name == rhs.name && lhs.typeName == rhs.typeName
    }
}

extension DDSTopic {
    /// Whether the data type supports loaning.
    /// - Note: This is always true if `Message` confroms to `DDSLoanable` and always false otherwise.
    public static var isLoaningCompatible: Bool {
        false
    }
}

extension DDSTopic where Message: DDSLoaningCodable {
    /// Whether the data type supports loaning.
    /// - Note: This is always true if `Message` confroms to `DDSLoanable` and always false otherwise.
    public static var isLoaningCompatible: Bool {
        true
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
    ///   - convention: The naming convention to use for the topic. Default is `.default`.
    /// - Throws: If the topic cannot be created.
    /// - Returns: The new topic.
    @inlinable
    public func getTopic<T: DDSMessage>(named name: String, type: T.Type, convention: DDSNamespace.NamingConvention = .default) throws(DDSError) -> DDSTopic<T> {
        try DDSTopic<T>(participant: self, topic: name, convention: convention)
    }
}
