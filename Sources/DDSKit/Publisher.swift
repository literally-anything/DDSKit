/**
 * Publisher.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/05/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import Synchronization
internal import _CFastDDS

/// A publisher for a DDS topic.
/// 
/// A publisher is used to publish messages to a topic.
public final class DDSPublisher<Message: DDSCodable> : @unchecked Sendable {
    /// The topic that this publisher is publishing on.
    public let topic: DDSTopic<Message>
    /// A wrapper around the underlying FastDDS DataWriter.
    /// The wrapper is needed because the FastDDS DataWriter is mostly virtual and fails to import into swift.
    internal var raw: FastDDS.DataWriter

    /// A list of callbacks to call when a the subscriber count goes above 0.
    /// This list is cleared after every time the callbacks are run.
    private let matchCallbacks: Mutex<[@Sendable (borrowing DDSEntityIdentifier) -> Void]> = Mutex([])

    /// Initializes a new DDSPublisher on the given topic and with the given settings.
    /// - Parameters:
    ///   - topic: The topic to publish on.
    ///   - settings: An optional list of settings for the publisher.
    /// - Throws: DDSError if the publisher fails to initialize.
    public init(topic: DDSTopic<Message>, settings: [Setting] = []) throws(DDSError) {
        self.topic = topic

        var qos = FastDDS.DataWriter.Qos(publisher: topic.participant.rawPublisher)

        for setting in settings {
            switch setting {
                case .operatingMode(let mode):
                    qos.setOperatingMode(push: mode == .push)
                case .dataSharing(let mode):
                    switch mode {
                        case .on(let dir):
                            qos.setDataSharingMode(dir: dir ?? "")
                        case .off:
                            qos.setDataSharingModeOff()
                    }
                case .publishMode(let mode):
                    qos.setPublishMode(async: mode == .async)
            }
        }

        var success = false
        raw = FastDDS.DataWriter(
            topic: topic.raw, publisher: topic.participant.rawPublisher,
            profile: qos,
            success: &success
        )
        if !success {
            throw DDSError.initializationError(from: .dataWriter)
        }

        try FastDDSErrorCode.checkThrowInternal(
            raw.setCallbacks(
                .init { [unowned self] subscriptionCount, countChange, instanceHandle in
                    // Called when the number of subscriptions changes
                    if subscriptionCount > 0 {
                        matchCallbacks.withLock { callbacks in
                            guard !callbacks.isEmpty else {
                                return
                            }

                            let entityIdentifier = DDSEntityIdentifier(guid: FastDDS.guidFromInstanceHandle(instanceHandle))

                            for callback in callbacks {
                                callback(entityIdentifier)
                            }
                            callbacks.removeAll()
                        }
                    }
                }
            ),
            from: .dataWriter
        )

        try FastDDSErrorCode.checkThrow(raw.enable())
    }

    deinit {
        let ret = FastDDSErrorCode.check(raw.destroy())
        if let ret {
            let error = DDSError.destructionError(
                from: .dataWriter,
                ret
            )
            fatalError("\(error)")
        }
    }
}

extension DDSPublisher {
    /// The entity identifier of the publisher.
    public var identifier: DDSEntityIdentifier {
        DDSEntityIdentifier(guid: raw.guid)
    }

    /// The current number of subscribers to the topic.
    public var subscriberCount: Int {
        Int(raw.matchedCount)
    }

    /// Waits for a subscriber to subscribe to the topic.
    /// Returns immediately if there is already a subscriber.
    public func waitForSubscriber() async {
        if raw.matchedCount > 0 {
            return
        }

        await withUnsafeContinuation { continuation in
            matchCallbacks.withLock { callbacks in
                callbacks.append { _ in
                    continuation.resume()
                }
            }
        }
    }
}

extension DDSPublisher {
    /// Some metadata that can be attached to a message to provide more context.
    /// This can be used for request-reply patterns or other specific use cases.
    public struct MessageMetadata: Sendable {
        /// The identifier of a related message.
        /// This is used mainly for request-reply patterns or similar.
        /// This should be set by the user when sending the message, and it can be read in a message callback from a subscriber.
        public var relatedIdentifier: DDSMessageIdentifier?

        /// The timestamp of the message.
        /// If not set here, this is set automatically when the message is sent.
        /// This should only be used for very specific use cases.
        /// This is in seconds since the epoch.
        public var timestamp: Double?

        /// Creates a new message metadata.
        /// - Parameters:
        ///   - relatedIdentifier: An optional identifier of a related message.
        ///   - timestamp: An optional timestamp of the message. This will be autogenerated if not provided.
        public init(relatedIdentifier: DDSMessageIdentifier? = nil, timestamp: Double? = nil) {
            self.relatedIdentifier = relatedIdentifier
            self.timestamp = timestamp
        }
    }
}

extension DDSPublisher {
    /// Publishes raw data to the topic.
    /// This is separated from `publish` because it is private, and to allow `publish` to be @inlinable and generalized in another module.
    /// - Parameters
    ///   - data: The raw data to publish.
    /// - Throws: DDSError if the data fails to publish.
    @usableFromInline
    internal func publishRaw(_ sample: UnsafeRawPointer) throws(DDSError) {
        let retcode = raw.write(data: sample)
        if let error = FastDDSErrorCode.check(retcode) {
            throw DDSError.publishError(error)
        }
    }
    /// Publishes a message to the topic.
    /// - Parameters
    ///   - message: The message to publish.
    /// - Throws: DDSError if the message fails to publish.
    @inlinable
    public func publish(_ message: borrowing Message) throws(DDSError) {
        try withUnsafePointer(to: message) { messagePtr throws(DDSError) in
            try publishRaw(messagePtr)
        }
    }

    /// Publishes raw data to the topic with metadata.
    /// This is separated from `publish` because it is private, and to allow `publish` to be @inlinable and generalized in another module.
    /// - Parameters
    ///   - data: The raw data to publish.
    ///   - metadata: The metadata to attach to the message.
    /// - Returns: The identifier of the sent message.
    /// - Throws: DDSError if the data fails to publish.
    @usableFromInline
    @discardableResult
    internal func publishRawWithMetadata(_ sample: UnsafeRawPointer, metadata: MessageMetadata? = nil) throws(DDSError) -> DDSMessageIdentifier {
        let relatedIdentifier = metadata?.relatedIdentifier
        var sampleIdentitiy = FastDDS.SampleIdentity()

        let retcode = raw.write(
            data: sample,
            related: relatedIdentifier.sampleIdentity, this: &sampleIdentitiy,
            timestamp: metadata?.timestamp ?? -1
        )
        if let error = FastDDSErrorCode.check(retcode) {
            throw DDSError.publishError(error)
        }

        return DDSMessageIdentifier(sampleIdentitiy)!
    }
    /// Publishes a message to the topic with metadata.
    /// - Parameters
    ///   - message: The message to publish.
    ///   - metadata: The optional metadata to attach to the message.
    /// - Returns: The identifier of the sent message.
    /// - Throws: DDSError if the message fails to publish.
    @inlinable
    @discardableResult
    public func publishWithMetadata(_ message: borrowing Message, metadata: MessageMetadata? = nil) throws(DDSError) -> DDSMessageIdentifier {
        try withUnsafePointer(to: message) { messagePtr throws(DDSError) in
            try publishRawWithMetadata(messagePtr, metadata: metadata)
        }
    }
}

extension DDSPublisher where Message: DDSLoaningCodable {
    /// Sets how to initialize the memory when publishing a loaned message.
    public enum LoanInitializationMode {
        /// The memory will be in an undefined state (Could be 0, or could be old data). All values should be set manually before publishing.
        case none
        /// The memory will be zeroed out before loaning. This is the default mainly for safety.
        case zero
        /// This will call the default initializer for the type to initialize the memory.
        case constructed
    }

    /// Loans a message from the publisher.
    /// This is only supported for plain and bounded types.
    /// This is separated from `publish` because it is private, and to allow `publish` to be @inlinable and generalized in another module.
    /// - Parameter initializationMode: How to initialize the memory in the sample. Defaults to zero.
    /// - Returns: A pointer to the loaned message.
    /// - Throws: DDSError if the loan fails.
    @usableFromInline
    internal func loan(initializationMode: LoanInitializationMode = .zero) throws(DDSError) -> UnsafeMutableRawPointer {
        precondition(Message.ddsTopicType.typeSupport.isPlain(), "Loan is only supported for plain and bounded types.")

        // The LoanInitiationKind enum isn't bridged to swift. This is a painful workaround.
        let initKind: CInt = switch initializationMode {
            case .none:
                FastDDS.DataWriter.getLoanInitKindNone()
            case .zero:
                FastDDS.DataWriter.getLoanInitKindZero()
            case .constructed:
                FastDDS.DataWriter.getLoanInitKindConstructed()
        }

        var sample: UnsafeMutableRawPointer?
        let retcode = raw.loan(dataPtr: &sample, initKind: initKind)
        if let error = FastDDSErrorCode.check(retcode) {
            throw DDSError.publishError(error)
        }
        return sample!
    }
    /// Discards a loaned previously message.
    /// This only needs to be called when the loaned message is not published. Publishing also discards the loaned sample.
    /// This is separated from `publish` because it is private, and to allow `publish` to be @inlinable and generalized in another module.
    /// - Parameter sample: The loaned message to discard.
    /// - Throws: DDSError if the loan fails.
    @usableFromInline
    internal func discardLoan(_ sample: consuming UnsafeMutableRawPointer) throws(DDSError) {
        let retcode = raw.discardLoan(dataPtr: &sample)
        if let error = FastDDSErrorCode.check(retcode) {
            throw DDSError.publishError(error)
        }
    }

    /// Publishes a message to the without any copies.
    /// This is useful for performance critical code.
    /// - Warning: Neither `publish` method should be called inside the `body` closure. This will cause undefined behavior when the closure ends.
    /// - Parameters:
    ///   - initializationMode: How to initialize the memory before it's passed into `body`. Defaults to `.zero` (Initialized to zero).
    ///   - body: A closure that takes a inout message and modifies it.
    /// - Throws: DDSError if the message fails to publish.
    /// - Throws: E if the body throws.
    @inlinable
    public func publish<E: Error>(initializationMode: LoanInitializationMode = .zero, _ body: (inout Message) throws(E) -> Void) throws {
        let sample = try loan(initializationMode: initializationMode)

        do throws(E) {
            let message = sample.assumingMemoryBound(to: Message.self)
            try body(&message.pointee)
        } catch {
            // On error, discard the loaned message.
            try discardLoan(sample)
            throw error
        }

        // Publish the loaned message (DDS takes ownership of the memory, so no need to discard).
        try publishRaw(sample)
    }
}

/// Settings for a `DDSPublisher`.
public enum DDSPublisherSetting {
    /// Sets the operating mode of the publisher. Defaults to `.push`.
    case operatingMode(OperatingMode)
    /// Sets the data sharing mode of the publisher. Defaults to automatically pick based on whether it is supported with this config and data type.
    /// If set to on and it is not supported, an error will be thrown when initializing the publisher.
    case dataSharing(DataSharingMode)
    /// Sets whether to publish synchronously or asynchronously.
    /// Whether publish calls should block.
    case publishMode(PublishMode)

    /// The operating mode of the publisher.
    public enum OperatingMode {
        /// Immediately send data do subscribers. This is the default.
        case push
        /// Waits for the subsriber to request the data. (This happens under the hood).
        case pull
    }

    /// The data sharing mode of the publisher.
    /// When this is on, the publisher will share it's history with subscribers through shared memory.
    /// This defualts to automatically picks based on whether it is supported with this config and data type.
    /// If set to on and it is not supported, an error will be thrown when initializing the publisher.
    public enum DataSharingMode {
        /// The publisher will directly share it's history with subscribers with shared memory.
        /// - Parameter dir: The path to the directory to use for memory-mapped files. Nil to use the default.
        case on(dir: String? = nil)
        /// The publisher will send data to subscribers as normal.
        case off

        /// The publisher will directly share it's history with subscribers with shared memory.
        static var on: DataSharingMode { .on() }
    }

    /// The publish mode of the publisher.
    /// Whether publish calls should block.
    public enum PublishMode {
        /// Publish calls will block until the data is sent.
        case sync
        /// Publish calls will return immediately and the data will be sent in the background.
        case async
    }
}

extension DDSPublisher {
    /// Settings for the publisher.
    public typealias Setting = DDSPublisherSetting
}

extension DDSPublisher {
    /// Whether the data type supports loaning.
    /// - Note: This is always true if `Message` confroms to `DDSLoanable` and always false otherwise.
    @inlinable
    public static var isLoaningCompatible: Bool {
        DDSTopic<Message>.isLoaningCompatible
    }

    /// Whether the data type supports loaning.
    /// - Note: This is always true if `Message` confroms to `DDSLoanable` and always false otherwise.
    @inlinable
    public var isLoaningCompatible: Bool {
        Self.isLoaningCompatible
    }
}

extension DDSPublisher: CustomStringConvertible {
    public var description: String {
        "DDSPublisher(topic: \(topic))"
    }
}

extension DDSParticipant {
    /// Creates a new publisher on this participant.
    /// This is a convenience function that creates a topic from the name and type and uses that to create a Publisher.
    /// - Parameters:
    ///   - topicName: The name of the topic to publish to.
    ///   - type: The message data type of the topic.
    ///   - settings: A list of settings to apply to the publisher.
    /// - Throws: If the publisher cannot be created.
    public func publish<T: DDSCodable>(to topicName: String, type: T.Type, settings: [DDSPublisher<T>.Setting] = []) throws(DDSError) -> DDSPublisher<T> {
        try DDSPublisher(
            topic: DDSTopic<T>(participant: self, topic: topicName),
            settings: settings
        )
    }
}

extension DDSTopic {
    /// Creates a new publisher on this topic.
    /// - Parameter settings: A list of settings to apply to the publisher.
    /// - Throws: If the publisher cannot be created.
    /// - Returns: The new publisher.
    public func publish(settings: [DDSPublisher<Message>.Setting] = []) throws(DDSError) -> DDSPublisher<Message> {
        try DDSPublisher(topic: self, settings: settings)
    }
}


