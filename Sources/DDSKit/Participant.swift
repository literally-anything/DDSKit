/**
 * Participant.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/03/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS
internal import _FastDDSHelpers

// extension Participant: DestroyableEntity {}
// extension Publisher: DestroyableEntity {}
// extension Subscriber: DestroyableEntity {}

public final class DDSParticipant: @unchecked Sendable {
    /// A wrapper around the underlying FastDDS DomainParticipant.
    /// The wrapper is needed because the FastDDS DomainParticipant is mostly virtual and fails to import into swift.
    internal var raw: FastDDS.Participant

    /// A wrapper around the underlying FastDDS Publisher.
    /// This is not a DDSPublisher! It is a FastDDS Publisher which allows you to allocate DataWriters.
    /// The wrapper is needed because the FastDDS Publisher is mostly virtual and fails to import into swift.
    internal var rawPublisher: FastDDS.Publisher

    /// A wrapper around the underlying FastDDS Subscriber.
    /// This is not a DDSSubscriber! It is a FastDDS Subscriber which allows you to allocate DataReaders.
    /// The wrapper is needed because the FastDDS Subscriber is mostly virtual and fails to import into swift.
    internal var rawSubscriber: FastDDS.Subscriber

    /// The callbacks for the FastDDS DomainParticipant.
    /// This allows swift functions to be called from the DomainParticipantListener while keeping context and not using @convention(c).
    /// This may be replaced with clang blocks in the future.
    private var callbacks = ParticipantCallbacks()

    /// Initializes a new DDSParticipant.
    /// - Parameter domain: The domain id for the participant. Only other participants in the same domain can communicate with each other. Defaults to 0.
    /// - Throws: DDSError if the participant fails to initialize.
    public init(domain: UInt32 = 0) throws(DDSError) {
        FastDDS.initLogging()

        var success = false

        raw = withUnsafePointer(to: callbacks) { callbacksPtr in
            FastDDS.Participant(
                domain: domain,
                profile: FastDDS.Participant.getDefaultQos(),
                callbacks: .init(callbacksPtr), statusMask: [],
                success: &success
            )
        }
        guard success else {
            throw DDSError.initializationError(from: .participant)
        }

        rawPublisher = FastDDS.Publisher(
            participant: raw, 
            profile: FastDDS.Publisher.getDefaultQos(participant: raw),
            success: &success
        )
        guard success else {
            throw DDSError.initializationError(from: .publisher)
        }

        rawSubscriber = FastDDS.Subscriber(
            participant: raw,
            profile: FastDDS.Subscriber.getDefaultQos(participant: raw),
            success: &success
        )
        guard success else {
            throw DDSError.initializationError(from: .subscriber)
        }
    }

    deinit {
        // Publisher and Subscriber are destroyed by the Participant's destroy function
        let ret = FastDDSErrorCode.check(raw.destroy())
        if let ret {
            let error = DDSError.destructionError(
                from: .participant,
                ret
            )
            fatalError("\(error)")
        }
    }

    /// The domain id of the participant.
    /// Only other participants in the same domain can communicate with each other.
    public var domain: UInt32 {
        raw.domain
    }
}

extension DDSParticipant {
    @inlinable
    public func publish<T: CDRCodable>(to topic: DDSTopic<T>) throws(DDSError) -> DDSPublisher<T> {
        try DDSPublisher(topic: topic)
    }

    @inlinable
    public func publish<T: CDRCodable>(to topicName: String, type: T.Type) throws(DDSError) -> DDSPublisher<T> {
        try publish(
            to: DDSTopic<T>(participant: self, topic: topicName)
        )
    }
}

extension DDSParticipant {
    @inlinable
    public func subscribe<T: CDRCodable>(to topic: DDSTopic<T>) throws(DDSError) -> DDSSubscriber<T> {
        try DDSSubscriber(topic: topic)
    }

    @inlinable
    public func subscribe<T: CDRCodable>(to topicName: String, type: T.Type) throws(DDSError) -> DDSSubscriber<T> {
        try subscribe(
            to: DDSTopic<T>(participant: self, topic: topicName)
        )
    }
}

extension DDSParticipant {
    /// Registers a type with the participant.
    /// This shouldn't be called directly. Instead, DDSTopic should call it in it's initializer.
    /// - Parameter type: The type to register.
    /// - Throws: DDSTypeError if the type fails to register.
    internal func registerType<T: CDRCodable>(_ type: T.Type) throws(DDSTypeError) {
        let error = FastDDSErrorCode.check(raw.registerType(typeSupport: type.ddsTopicType))
        
        if let error {
            switch error {
                // Returned when the type name is size 0
                case .badParameter:
                    throw .invalidName
                // Returned when the type name is already registered
                case .preconditionFailed:
                    throw .alreadyRegistered
                default:
                    assertionFailure("Got unexpected return code when registering FastDDS type: \(error)")
            }
        }
    }
}

extension DDSParticipant: CustomStringConvertible {
    public var description: String {
        "DDSParticipant(domain: \(domain))"
    }
}
