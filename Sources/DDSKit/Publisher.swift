/**
 * Publisher.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/05/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import Synchronization
internal import _CFastDDS

// extension DataWriter: DestroyableEntity {}


public final class DDSPublisher<Message: CDRCodable> : @unchecked Sendable {
    /// The topic that this publisher is publishing on.
    public let topic: DDSTopic<Message>
    /// A wrapper around the underlying FastDDS DataWriter.
    /// The wrapper is needed because the FastDDS DataWriter is mostly virtual and fails to import into swift.
    internal var raw: FastDDS.DataWriter

    /// A list of callbacks to call when a the subscriber count goes above 0.
    /// This list is cleared after every time the callbacks are run.
    private let matchCallbacks: Mutex<[() -> Void]> = Mutex([])

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

        try FastDDSErrorCode.checkThrow(
            raw.setCallbacks(
                .init { [unowned self] subscriptionCount, countChange in
                    // Called when the number of subscriptions changes
                    if subscriptionCount > 0 {
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
                }
            ),
            from: .dataWriter
        )

        try FastDDSErrorCode.checkThrow(raw.enable())
    }
}

extension DDSPublisher {
    /// Publishes raw data to the topic.
    /// This is separated from `publish` because it is private, and to allow `publish` to be @inlinable and generalized in another module.
    /// - Parameter data: The raw data to publish.
    /// - Throws: DDSError if the data fails to publish.
    @usableFromInline
    internal func publishRaw(_ sample: consuming UnsafeRawPointer) throws(DDSError) {
        let retcode = raw.write(data: sample)
        if let error = FastDDSErrorCode.check(retcode) {
            throw DDSError.publishError(error)
        }
    }

    /// Publishes a message to the topic.
    /// - Parameter message: The message to publish.
    /// - Throws: DDSError if the message fails to publish.
    @inlinable
    public func publish(_ message: borrowing Message) throws(DDSError) {
        try withUnsafePointer(to: message) { messagePtr throws(DDSError) in
            try publishRaw(messagePtr)
        }
    }
}

extension DDSPublisher {
    /// Loans a message from the publisher.
    /// This is only supported for plain and bounded types.
    /// This is separated from `publish` because it is private, and to allow `publish` to be @inlinable and generalized in another module.
    /// - Parameter initializationMode: How to initialize the memory in the sample.
    /// - Returns: A pointer to the loaned message.
    /// - Throws: DDSError if the loan fails.
    @usableFromInline
    internal func loan(initializationMode: LoanInitializationMode) throws(DDSError) -> UnsafeMutableRawPointer {
        precondition(Message.ddsTopicType.typeSupport.is_bounded(), "Loan is only supported for plain and bounded types.")

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
        raw.loan(dataPtr: &sample, initKind: initKind)
        return sample!
    }
    /// Discards a loaned previously message.
    /// This only needs to be called when the loaned message is not published. Publishing also discards the loaned sample.
    /// This is separated from `publish` because it is private, and to allow `publish` to be @inlinable and generalized in another module.
    /// - Parameter sample: The loaned message to discard.
    /// - Throws: DDSError if the loan fails.
    @usableFromInline
    internal func discardLoan(_ sample: consuming UnsafeMutableRawPointer) throws(DDSError) {
        raw.discardLoan(dataPtr: &sample)
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
    public func publish<E: Error>(initializationMode: LoanInitializationMode = .zero, body: (inout Message) throws(E) -> Void) throws {
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

    /// Sets how to initialize the memory when publishing a loaned message.
    public enum LoanInitializationMode {
        /// The memory will be in an undefined state (Could be 0, or could be old data). All values should be set manually before publishing.
        case none
        /// The memory will be zeroed out before loaning. This is the default mainly for safety.
        case zero
        /// This will call the default initializer for the type to initialize the memory.
        case constructed
    }
}

extension DDSPublisher {
    /// The current number of subscribers to the topic.
    public var subscriberCount: Int {
        Int(raw.matchedCount)
    }

    /// Waits for a subscriber to subscribe to the topic.
    /// Returns immediately if there is already a subscriber.
    public func waitForSubscriber() async {
        guard raw.matchedCount <= 0 else {
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

extension DDSPublisher: CustomStringConvertible {
    public var description: String {
        "DDSPublisher(topic: \(topic))"
    }
}

extension DDSPublisher {
    /// A setting for the publisher.
    public enum Setting {
        /// Sets the operating mode of the publisher. Defaults to `.push`.
        case operatingMode(OperatingMode)
        /// Sets the data sharing mode of the publisher. Defaults to automatically pick based on whether it is supported with this config and data type.
        /// If set to on and it is not supported, an error will be thrown when initializing the publisher.
        case dataSharing(DataSharingMode)

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
    }
}
