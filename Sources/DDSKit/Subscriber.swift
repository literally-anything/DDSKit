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

public final class DDSSubscriber<T: CDRCodable> : @unchecked Sendable {
    /// The topic that this subscriber is subscribed to.
    public let topic: DDSTopic<T>
    /// A wrapper around the underlying FastDDS DataReader.
    /// The wrapper is needed because the FastDDS DataReader is mostly virtual and fails to import into swift.
    internal var raw: FastDDS.DataReader

    /// A list of callbacks to call when a the publisher count goes above 0.
    /// This list is cleared after every time the callbacks are run.
    private let matchCallbacks: Mutex<[() -> Void]> = Mutex([])

    /// A list of callbacks to call when a message arrives.
    /// If a callback returns true, it will be removed from the list.
    @usableFromInline
    internal let dataCallbacks: Mutex<[(UnsafeRawPointer) -> Bool]> = Mutex([])

    public init(topic: DDSTopic<T>, settings: [Setting] = []) throws(DDSError) {
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
            success: &success
        )
        if !success {
            throw DDSError.initializationError(from: .dataReader)
        }

        try FastDDSErrorCode.checkThrowInternal(
                raw.setCallbacks(
                .init { [unowned self] publisherCount, countChange in
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
                } onDataCallback: { [unowned self] dataPtr in
                    // Called when a new message is received
                    dataCallbacks.withLock { callbacks in
                        guard !callbacks.isEmpty else {
                            return
                        }

                        var index = callbacks.count - 1
                        let reversedCallbacks: ReversedCollection<_> = callbacks.reversed()
                        for callback in reversedCallbacks {
                            if callback(dataPtr) {
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
}

extension DDSSubscriber {
    /// The current number of publishers on the topic.
    public var publisherCount: Int {
        Int(raw.matchedCount)
    }

    /// Waits for a publisher to be created on the topic.
    /// Returns immediately if there is already a publisher.
    public func waitForPublisher() async {
        print(raw.matchedCount)
        guard raw.matchedCount >= 0 else {
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
    @inlinable
    public var messages: AsyncStream<T> {
        AsyncStream { continuation in
            let end = Atomic(false)
            dataCallbacks.withLock { @Sendable callbacks in
                callbacks.append { dataPtr in
                    guard !end.load(ordering: .relaxed) else {
                        return true
                    }
                    guard case .enqueued(_) = continuation.yield(dataPtr.assumingMemoryBound(to: T.self).pointee) else {
                        return true
                    }
                    return false
                }
            }
            continuation.onTermination = { @Sendable _ in
                end.store(true, ordering: .sequentiallyConsistent)
            }
        }
    }
}

extension DDSSubscriber: CustomStringConvertible {
    public var description: String {
        "DDSSubscriber(topic: \(topic))"
    }
}

extension DDSSubscriber {
    /// A setting for the subscriber.
    public enum Setting {
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
}
