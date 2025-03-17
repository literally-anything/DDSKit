/**
 * Subscriber.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/06/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
public import Synchronization
internal import _CFastDDS

/// A subscriber for a topic.
/// 
/// A subscriber is used to receive messages from a topic.
public final class DDSSubscriber<Message: DDSMessage> : @unchecked Sendable {
    /// The topic that this subscriber is subscribed to.
    public let topic: DDSTopic<Message>
    /// A wrapper around the underlying FastDDS DataReader.
    /// The wrapper is needed because the FastDDS DataReader is mostly virtual and fails to import into swift.
    internal var raw: FastDDS.DataReader

    /// A list of callbacks to call when a the publisher count goes above 0.
    /// This list is cleared after every time the callbacks are run.
    private let matchCallbacks: Mutex<[@Sendable (borrowing DDSEntityIdentifier) -> Void]> = Mutex([])
    /// A list of callbacks to call when a message arrives.
    /// If a callback returns true, it will be removed from the list.
    @usableFromInline
    internal let dataCallbacks: Mutex<[@Sendable (UnsafeRawPointer, borrowing MessageMetadata) -> Bool]> = Mutex([])
    /// A list of callbacks to call when an error occurs while loaning messages.
    /// If a callback returns true, it will be removed from the list.
    @usableFromInline
    internal let errorCallbacks: Mutex<[@Sendable (Int32) -> Bool]> = Mutex([])

    /// The participant that the subscriber is on.
    public var participant: DDSParticipant {
        topic.participant
    }

    /// Creates a new subscriber on a topic.
    /// - Parameters:
    ///   - topic: The topic to subscribe to.
    ///   - settings: A list of settings to apply to the subscriber.
    /// - Throws: If the subscriber cannot be created.
    public init(topic: DDSTopic<Message>, settings: [Setting] = []) throws(DDSError) {
        self.topic = topic

        var qos = FastDDS.DataReader.Qos(subscriber: topic.participant.rawSubscriber)

        for setting in settings {
            switch setting {
                case .loadProfile(let name):
                    var ret: Int32 = 0
                    qos = .init(subscriber: topic.participant.rawSubscriber, profileName: .init(name), ret: &ret)
                    if let error = FastDDSErrorCode.check(ret) {
                        throw .profileError(name: name, error)
                    }
                case .dataSharing(let mode):
                    switch mode {
                        case .on(let dir):
                            qos.setDataSharingMode(dir: dir ?? "")
                        case .off:
                            qos.setDataSharingModeOff()
                        case .auto:
                            qos.setDataSharingModeAuto()
                    }
                case .historyDepth(let depth):
                    switch depth {
                        case .endless:
                            qos.setHistoryDepthEndless()
                        case .depth(let depth):
                            qos.setHistoryDepth(depth)
                    }
                case .timeout(let timeout):
                    qos.setMaxBlockingTime(Int32(timeout.components.seconds), UInt32(Double(timeout.components.attoseconds) * 1e-9))
                case .reliability(let reliability):
                    qos.setReliability(reliability == .reliable)
            }
        }

        var success = false
        raw = FastDDS.DataReader(
            topic: topic.raw, subscriber: topic.participant.rawSubscriber,
            profile: qos,
            loanable: Self.isLoaningCompatible,
            success: &success
        )
        if !success {
            throw DDSError.initializationError(from: .dataReader)
        }

        try FastDDSErrorCode.checkThrowInternal(
            raw.setCallbacks(
                .init { @Sendable [unowned self] publisherCount, countChange, guid in
                    // Called when the number of publishers changes
                    if publisherCount > 0 {
                        matchCallbacks.withLock { callbacks in
                            guard !callbacks.isEmpty else {
                                return
                            }

                            let entityIdentifier = DDSEntityIdentifier(guid: guid)

                            for callback in callbacks {
                                callback(entityIdentifier)
                            }
                            callbacks.removeAll()
                        }
                    }
                } onDataCallback: { @Sendable [unowned self] dataPtr, info in
                    // Called when a new message is received
                    dataCallbacks.withLock { callbacks in
                        guard !callbacks.isEmpty else {
                            return
                        }

                        let metadata = MessageMetadata(info: info.pointee)

                        var index = callbacks.count - 1
                        let reversedCallbacks: ReversedCollection<_> = callbacks.reversed()
                        for callback in reversedCallbacks {
                            if callback(dataPtr, metadata) {
                                callbacks.remove(at: index)
                            }
                            index -= 1
                        }
                    }
                } onErrorCallback: { @Sendable [unowned self] errorCode in
                    // Called when an unexpexted error is encountered while loaning messages
                    errorCallbacks.withLock { callbacks in
                        guard !callbacks.isEmpty else {
                            return
                        }

                        var index = callbacks.count - 1
                        let reversedCallbacks: ReversedCollection<_> = callbacks.reversed()
                        for callback in reversedCallbacks {
                            if callback(errorCode) {
                                callbacks.remove(at: index)
                            }
                            index -= 1
                        }
                    }
                }
            ),
            from: .dataReader
        )

        try FastDDSErrorCode.checkThrow(raw.enable())
    }

    deinit {
        let ret = FastDDSErrorCode.check(raw.destroy())
        if let ret {
            let error = DDSError.destructionError(
                from: .dataReader,
                ret
            )
            fatalError("\(error)")
        }
    }
}

extension DDSSubscriber {
    /// The entity identifier of the subscriber.
    public var identifier: DDSEntityIdentifier {
        DDSEntityIdentifier(guid: raw.guid)
    }

    /// The current number of publishers on the topic.
    public var publisherCount: Int {
        Int(raw.matchedCount)
    }

    /// Waits for a publisher to be created on the topic.
    /// Returns immediately if there is already a publisher.
    /// - Returns: The entity identifier of the first publisher that is found. Or nil if there is already a publisher because I can't get the GUID of exisiting ones yet.
    @discardableResult
    public func waitForPublisher() async -> DDSEntityIdentifier? {
        if raw.matchedCount > 0 {
            return nil
        }

        // Use a continuation to wait for the next call to the match callback.
        return await withUnsafeContinuation { continuation in
            matchCallbacks.withLock { callbacks in
                // Don't actually escape because the callback is removed before we exit this context.
                withoutActuallyEscaping({ @Sendable in continuation.resume(returning: $0) }) { callback in
                    callbacks.append(callback)
                }
            }
        }
    }
}

extension DDSSubscriber {
    /// Some metadata that is returned with a message to provide more context.
    public struct MessageMetadata: Sendable {
        /// The underlying fastdds SampleInfo.
        internal let info: FastDDS.DataReader.SampleInfo

        /// The identifier of the message.
        public var identifier: DDSMessageIdentifier {
            DDSMessageIdentifier(.init(info.sample_identity))!
        }

        /// The identifier of a related message.
        /// This is used mainly for request-reply patterns or similar.
        public var relatedIdentifier: DDSMessageIdentifier? {
            DDSMessageIdentifier(.init(info.related_sample_identity))
        }

        /// The timestamp of when the message was sent.
        /// This is in seconds since the epoch.
        public var timestamp: Double {
            let seconds = Double(info.source_timestamp.seconds())
            let nanoseconds_fixed = Double(info.source_timestamp.nanosec()) * 1e-9
            let fraction_fixed = Double(info.source_timestamp.fraction()) * pow(2, -32)
            return seconds + nanoseconds_fixed + fraction_fixed
        }

        /// The identifier of the entity that sent the message.
        public var senderEntityIdentifier: DDSEntityIdentifier {
            DDSEntityIdentifier(guid: FastDDS.GUIDHelpers.guidFromInstanceHandle(info.publication_handle))
        }
    }
}

extension DDSSubscriber {
    /// A single error that can be thrown in a message callback to unregister the callback.
    public enum UnregisterCallbackError: Error {
        /// Unregisters the callback when thrown from a subscriber message callback.
        case unregister
    }

    @inlinable
    public func registerMessageCallback(_ callback: @escaping @Sendable (borrowing Message) throws(UnregisterCallbackError) -> Void) {
        dataCallbacks.withLock { callbacks in
            callbacks.append { dataPtr, _ in
                do throws(UnregisterCallbackError) {
                    try callback(dataPtr.assumingMemoryBound(to: Message.self).pointee)
                } catch {
                    return true
                }
                return false
            }
        }
    }

    internal func registerMessageCallback(
        _ callback: @escaping @Sendable (borrowing Message, borrowing MessageMetadata) throws(UnregisterCallbackError) -> Void
    ) {
        dataCallbacks.withLock { callbacks in
            callbacks.append { dataPtr, metadata in
                do throws(UnregisterCallbackError) {
                    try callback(dataPtr.assumingMemoryBound(to: Message.self).pointee, metadata)
                } catch {
                    return true
                }
                return false
            }
        }
    }
}

extension DDSSubscriber {
    /// Create an async stream of messages from the subscriber.
    /// - Parameter bufferingPolicy: The buffering policy to use for the stream.
    /// - Throws: If an error occurs while reading the message.
    @inlinable
    public func getMessageStream(bufferingPolicy: AsyncThrowingStream<Message, Error>.Continuation.BufferingPolicy) -> AsyncThrowingStream<Message, Error> {
        AsyncThrowingStream(bufferingPolicy: bufferingPolicy) { continuation in
            let end = Atomic(false)
            dataCallbacks.withLock { @Sendable callbacks in
                callbacks.append { dataPtr, _ in
                    guard !end.load(ordering: .relaxed) else {
                        return true
                    }
                    if case .enqueued(_) = continuation.yield(dataPtr.assumingMemoryBound(to: Message.self).pointee) {
                        return false
                    }
                    end.store(true, ordering: .sequentiallyConsistent)
                    return true
                }
            }
            errorCallbacks.withLock { @Sendable callbacks in
                callbacks.append { errorCode in
                    do {
                        try FastDDSErrorCode.checkThrowInternal(errorCode, from: .dataReader)
                    } catch {
                        continuation.finish(throwing: error)
                    }
                    return true
                }
            }
            continuation.onTermination = { @Sendable _ in
                end.store(true, ordering: .sequentiallyConsistent)
            }
        }
    }
    /// Create an async stream of messages with metadata from the subscriber.
    /// - Parameter bufferingPolicy: The buffering policy to use for the stream.
    /// - Throws: If an error occurs while reading the message.
    @inlinable
    public func getMessageStreamWithMetadata(
        bufferingPolicy: AsyncThrowingStream<(Message, MessageMetadata), Error>.Continuation.BufferingPolicy
    ) -> AsyncThrowingStream<(Message, MessageMetadata), Error> {
        AsyncThrowingStream(bufferingPolicy: bufferingPolicy) { continuation in
            let end = Atomic(false)
            dataCallbacks.withLock { @Sendable callbacks in
                callbacks.append { dataPtr, metadata in
                    guard !end.load(ordering: .relaxed) else {
                        return true
                    }
                    if case .enqueued(_) = continuation.yield((dataPtr.assumingMemoryBound(to: Message.self).pointee, metadata)) {
                        return false
                    }
                    end.store(true, ordering: .sequentiallyConsistent)
                    return true
                }
            }
            errorCallbacks.withLock { @Sendable callbacks in
                callbacks.append { errorCode in
                    do {
                        try FastDDSErrorCode.checkThrowInternal(errorCode, from: .dataReader)
                    } catch {
                        continuation.finish(throwing: error)
                    }
                    return true
                }
            }
            continuation.onTermination = { @Sendable _ in
                end.store(true, ordering: .sequentiallyConsistent)
            }
        }
    }

    /// An async stream of messages from the subscriber.
    /// - Note: This stream is unbounded, so if the callback is too slow, it will continue to fill up.
    /// - Throws: If an error occurs while reading the message.
    @inlinable
    public var messages: AsyncThrowingStream<Message, Error> {
        getMessageStream(bufferingPolicy: .unbounded)
    }
    /// An async stream of messages from the subscriber.
    /// - Note: This stream buffers the latest 16 messages.
    /// - Throws: If an error occurs while reading the message.
    @inlinable
    public var messagesBounded: AsyncThrowingStream<Message, Error> {
        getMessageStream(bufferingPolicy: .bufferingNewest(16))
    }

    /// An async stream of messages with metadata from the subscriber.
    /// - Note: This stream is unbounded, so if the callback is too slow, it will continue to fill up.
    /// - Throws: If an error occurs while reading the message.
    @inlinable
    public var messagesWithMetadata: AsyncThrowingStream<(Message, MessageMetadata), Error> {
        getMessageStreamWithMetadata(bufferingPolicy: .unbounded)
    }
    /// An async stream of messages with metadata from the subscriber.
    /// - Note: This stream buffers the latest 16 messages.
    /// - Throws: If an error occurs while reading the message.
    @inlinable
    public var messagesWithMetadataBounded: AsyncThrowingStream<(Message, MessageMetadata), Error> {
        getMessageStreamWithMetadata(bufferingPolicy: .bufferingNewest(16))
    }
}

/// Settings for a `DDSSubscriber`.
public enum DDSSubscriberSettings {
    /// Loads a profile with the specified name from an XML file.
    /// These are documented in the FastDDS documentation: https://fast-dds.docs.eprosima.com/en/latest/fastdds/xml_configuration/xml_configuration.html
    /// - Warning: This is not recommended because there are many settings that aren't accounted for in this library, and messing with them can cause undefined behavior.
    /// - Parameter name: The name of the profile to load.
    case loadProfile(name: String)

    /// Sets the data sharing mode of the subscriber. Defaults to automatically pick based on whether it is supported with this config and data type.
    /// If set to on and it is not supported, an error will be thrown when initializing the subscriber.
    case dataSharing(DataSharingMode)

    /// Sets the history depth of the subscriber.
    /// Defaults to endless.
    /// - Parameters:
    ///   - depth: The depth of the history.
    case historyDepth(HistoryDepth)

    /// Sets the timeout for the subscriber.
    /// This is the maximum time to wait for any resource to be available.
    /// This only takes effect when `reliability` is set to `.reliable`.
    /// Some operations won't respect this timeout unless FastDDS is compiled with strict realtime support.
    /// When the timeout is reached, the operation will fail with a `DDSKit.timeout` error.
    /// - Parameters:
    ///   - timeout: The timeout to set.
    case timeout(Duration)

    /// Sets the reliability of the subscriber.
    /// Defaults to `.reliable`.
    /// - Parameters:
    ///   - reliability: The reliability to set.
    case reliability(Reliability)

    /// The data sharing mode of the subscriber.
    /// When this is on, the subscriber will share it's history with publisher through shared memory.
    /// This defualts to automatically picks based on whether it is supported with this config and data type.
    /// If set to on and it is not supported, an error will be thrown when initializing the subscriber.
    public enum DataSharingMode {
        /// The subscriber will directly share it's history with publishers with shared memory.
        /// - Parameter dir: The path to the directory to use for memory-mapped files. Nil to use the default.
        case on(dir: String? = nil)
        /// The subscriber will get data from publishers as normal.
        case off
        /// The subscriber will use the default data sharing mode for the topic and data type.
        case auto

        /// The subscriber will directly share it's history with subscribers with shared memory.
        static var on: DataSharingMode { .on() }
    }

    /// The depth of the history of the subscriber.
    public enum HistoryDepth: ExpressibleByIntegerLiteral {
        /// Don't drop any history until reaching system limits.
        case endless
        /// The history depth will be set to the given value.
        case depth(UInt32)

        /// Creates a new history depth.
        public init(integerLiteral value: UInt32) {
            self = .depth(value)
        }
    }

    /// The reliability of the subscriber.
    public enum Reliability {
        /// The subscriber will wait until there is space in a buffer to store a new message.
        case reliable
        /// The subscriber will drop any messages that don't fit in the buffer.
        case bestEffort
    }
}

extension DDSSubscriber {
    /// Settings for the subscriber.
    public typealias Setting = DDSSubscriberSettings
}

extension DDSSubscriber {
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

extension DDSSubscriber: CustomStringConvertible {
    public var description: String {
        "DDSSubscriber(topic: \(topic))"
    }
}

extension DDSParticipant {
    /// Creates a new subscriber on this participant.
    /// This is a convenience function that creates a topic from the name and type and uses that to create a Subscriber.
    /// - Parameters:
    ///   - topicName: The name of the topic to subscribe to.
    ///   - type: The message data type of the topic.
    ///   - settings: A list of settings to apply to the subscriber.
    /// - Throws: If the subscriber cannot be created.
    public func subscribe<T: DDSMessage>(to topicName: String, type: T.Type, settings: [DDSSubscriber<T>.Setting] = []) throws(DDSError) -> DDSSubscriber<T> {
        try DDSSubscriber(
            topic: DDSTopic<T>(participant: self, topic: topicName),
            settings: settings
        )
    }
}

extension DDSTopic {
    /// Creates a new subscriber on this topic.
    /// - Parameter settings: A list of settings to apply to the subscriber.
    /// - Throws: If the subscriber cannot be created.
    /// - Returns: The new subscriber.
    public func subscribe(settings: [DDSSubscriber<Message>.Setting] = []) throws(DDSError) -> DDSSubscriber<Message> {
        try DDSSubscriber(topic: self, settings: settings)
    }
}
