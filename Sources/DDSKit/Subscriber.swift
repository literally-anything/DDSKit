/**
 * Subscriber.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/06/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
public import Synchronization
internal import _CFastDDS

// extension DataReader: DestroyableEntity {}

/// A subscriber for a topic.
/// 
/// A subscriber is used to receive messages from a topic.
public final class DDSSubscriber<Message: DDSCodable> : @unchecked Sendable {
    /// The topic that this subscriber is subscribed to.
    public let topic: DDSTopic<Message>
    /// A wrapper around the underlying FastDDS DataReader.
    /// The wrapper is needed because the FastDDS DataReader is mostly virtual and fails to import into swift.
    internal var raw: FastDDS.DataReader

    /// A list of callbacks to call when a the publisher count goes above 0.
    /// This list is cleared after every time the callbacks are run.
    private let matchCallbacks: Mutex<[@Sendable () -> Void]> = Mutex([])
    /// A list of callbacks to call when a message arrives.
    /// If a callback returns true, it will be removed from the list.
    @usableFromInline
    internal let dataCallbacks: Mutex<[@Sendable (UnsafeRawPointer, borrowing MessageMetadata) -> Bool]> = Mutex([])
    /// A list of callbacks to call when an error occurs while loaning messages.
    /// If a callback returns true, it will be removed from the list.
    @usableFromInline
    internal let errorCallbacks: Mutex<[@Sendable (Int32) -> Bool]> = Mutex([])

    public init(topic: DDSTopic<Message>, settings: [Setting] = []) throws(DDSError) {
        self.topic = topic

        var qos = FastDDS.DataReader.Qos(subscriber: topic.participant.rawSubscriber)

        for setting in settings {
            switch setting {
                case .dataSharing(let mode):
                    switch mode {
                        case .on(let dir):
                            qos.setDataSharingMode(dir: dir ?? "")
                        case .off:
                            qos.setDataSharingModeOff()
                    }
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
                .init { @Sendable [unowned self] publisherCount, countChange in
                    // Called when the number of publishers changes
                    if publisherCount > 0 {
                        matchCallbacks.withLock { callbacks in
                            guard !callbacks.isEmpty else {
                                return
                            }

                            for callback in callbacks {
                                callback()
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

                        let metadata = MessageMetadata(info: info)

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
    /// The current number of publishers on the topic.
    public var publisherCount: Int {
        Int(raw.matchedCount)
    }

    /// Waits for a publisher to be created on the topic.
    /// Returns immediately if there is already a publisher.
    public func waitForPublisher() async {
        if raw.matchedCount > 0 {
            return
        }

        await withUnsafeContinuation { continuation in
            matchCallbacks.withLock { callbacks in
                callbacks.append {
                    continuation.resume()
                }
            }
        }
    }
}

extension DDSSubscriber {
    /// Some metadata that is returned with a message to provide more context.
    public struct MessageMetadata: @unchecked Sendable {
        /// The underlying fastdds SampleInfo.
        internal let info: UnsafePointer<FastDDS.DataReader.SampleInfo>

        /// The identifier of the message.
        public var identifier: DDSMessageIdentifier {
            DDSMessageIdentifier(.init(info.pointee.sample_identity))!
        }

        /// The identifier of a related message.
        /// This is used mainly for request-reply patterns or similar.
        public var relatedIdentifier: DDSMessageIdentifier? {
            DDSMessageIdentifier(.init(info.pointee.related_sample_identity))
        }

        /// The timestamp of when the message was sent.
        /// This is in seconds since the epoch.
        public var timestamp: Double {
            let seconds = Double(info.pointee.source_timestamp.seconds())
            let nanoseconds_fixed = Double(info.pointee.source_timestamp.nanosec()) * 1e-9
            let fraction_fixed = Double(info.pointee.source_timestamp.fraction()) * pow(2, -32)
            return seconds + nanoseconds_fixed + fraction_fixed
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
    @inlinable
    public var messages: AsyncThrowingStream<Message, Error> {
        AsyncThrowingStream(bufferingPolicy: .unbounded) { continuation in
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
}

/// Settings for a `DDSSubscriber`.
public enum DDSSubscriberSettings {
    /// Sets the data sharing mode of the subscriber. Defaults to automatically pick based on whether it is supported with this config and data type.
    /// If set to on and it is not supported, an error will be thrown when initializing the subscriber.
    case dataSharing(DataSharingMode)

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

        /// The subscriber will directly share it's history with subscribers with shared memory.
        static var on: DataSharingMode { .on() }
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
    public func subscribe<T: DDSCodable>(to topicName: String, type: T.Type, settings: [DDSSubscriber<T>.Setting] = []) throws(DDSError) -> DDSSubscriber<T> {
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
