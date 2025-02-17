/**
 * Participant.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/03/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import Synchronization
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

    /// A list of callbacks to call when a new participant is detected.
    /// The callback is passed the name of the detected participant.
    /// The callback will be automatically removed if it returns true. (This is needed because callbacks are not Equatable
    private let detectionCallbacks: Mutex<[(String) -> Bool]> = Mutex([])

    /// Initializes a new DDSParticipant.
    /// - Parameter domain: The domain id for the participant. Only other participants in the same domain can communicate with each other. Defaults to 0.
    /// - Parameter name: The user-defined name for the participant. Defaults to the name of the function that intialized the participant.
    /// - Parameter settings: An optional list of settings for the participant.
    /// - Throws: DDSError if the participant fails to initialize.
    public init(domain: UInt32 = 0, name: String = #function, settings: [Setting] = []) throws(DDSError) {
        /// In C++, this is represented as a fixed-size string, so it must be less than 256 characters.
        assert(name.count < 256, "Name must be less than 256 characters")
        if name.count >= 256 {
            _ = name.dropLast(name.count - 256)
        }

        // Setup swift-log with FastDDS. (Only happens on the first call)
        FastDDS.initLogging()

        var qos = FastDDS.Participant.getDefaultQos()

        // Don't auto enable the participant (enable is called after setup is done)
        qos.entity_factoryMutating(
            .init(
                /* autoenable: */ false
            )
        )

        name.withCString { cString in
            qos.nameMutating(.init(cString))
        }

        for setting in settings {
            switch setting {
                case .ignoreLocalEndpoints(let ignore):
                    FastDDS.QOSHelpers.PropertyPolicy.addProperty(to: &qos, name: "fastdds.ignore_local_endpoints", value: ignore ? "true" : "false")
            }
        }

        var success = false

        raw = FastDDS.Participant(
            domain: domain,
            profile: qos,
            success: &success
        )
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

        raw.setCallbacks(.init { [unowned self] participantNameC in
            // Called when new participant is discovered
            detectionCallbacks.withLock { callbacks in
                guard !callbacks.isEmpty else {
                    return
                }

                let name = String(cString: participantNameC)

                // This is reversed so that we can remove elements from the array while iterating
                for (index, callback) in callbacks.enumerated().reversed() {
                    // Remove the callback if it returns true
                    if callback(name) {
                        callbacks.remove(at: index)
                    }
                }
            }
        })

        raw.enable()
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

    /// The user-defined name of the participant.
    public var name: String {
        String(cString: raw.name)
    }
}

extension DDSParticipant {
    /// A list of the other participants' names on the same domain.
    public var participants: [String] {
        raw.participants.map { stdString in
            String(stdString)
        }
    }

    /// Waits for a participant to join the domain.
    /// Will return immediately if the specified participant is already in the domain.
    /// - Parameter name: The name of the participant to wait for.
    public func waitForParticipant(named name: String) async {
        assert(name != self.name, "Cannot wait for self")

        // Check if the participant is already in the domain
        if participants.contains(name) {
            return
        }

        await withUnsafeContinuation { continuation in
            detectionCallbacks.withLock { callbacks in
                callbacks.append { participantName in
                    guard participantName == name else {
                        return false
                    }
                    continuation.resume()
                    return true
                }
            }
        }
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
        "DDSParticipant(domain: \(domain), name: \(name))"
    }
}

extension DDSParticipant {
    /// A setting for the participant.
    public enum Setting {
        /// Sets whether to ingnore DataReaders and DataWriters that are created from the same participant.
        /// Defaults to false.
        case ignoreLocalEndpoints(Bool)
    }
}
