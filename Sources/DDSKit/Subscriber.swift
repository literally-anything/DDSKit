/**
 * Subscriber.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/06/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS
internal import _FastDDSHelpers

// extension DataReader: DestroyableEntity {}

public final class DDSSubscriber<T: CDRCodable> : @unchecked Sendable {
    public let topic: DDSTopic<T>
    internal var raw: FastDDS.DataReader
    private var callbacks = ReaderCallbacks()

    public init(topic: DDSTopic<T>) throws(DDSError) {
        self.topic = topic

        var success = false
        raw = withUnsafeMutablePointer(to: &callbacks) { callbacksPtr in
            FastDDS.DataReader(
                topic: topic.raw, subscriber: topic.participant.rawSubscriber,
                profile: FastDDS.DataReader.getDefaultQos(subscriber: topic.participant.rawSubscriber),
                callbacks: .init(callbacksPtr), statusMask: [],
                success: &success
            )
        }
        if !success {
            throw DDSError.initializationError(from: .dataReader)
        }

        raw.enable()
    }
}

extension DDSSubscriber: CustomStringConvertible {
    public var description: String {
        "DDSSubscriber(topic: \(topic))"
    }
}
