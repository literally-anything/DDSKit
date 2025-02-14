/**
 * Publisher.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/05/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS
internal import _FastDDSHelpers

// extension DataWriter: DestroyableEntity {}

public final class DDSPublisher<T: CDRCodable> : @unchecked Sendable {
    public let topic: DDSTopic<T>
    internal var raw: FastDDS.DataWriter
    private var callbacks = WriterCallbacks()

    public init(topic: DDSTopic<T>) throws(DDSError) {
        self.topic = topic

        var success = false
        raw = withUnsafeMutablePointer(to: &callbacks) { callbacksPtr in
            FastDDS.DataWriter(
                topic: topic.raw, publisher: topic.participant.rawPublisher,
                profile: FastDDS.DataWriter.getDefaultQos(publisher: topic.participant.rawPublisher),
                callbacks: .init(callbacksPtr), statusMask: [],
                success: &success
            )
        }
        if !success {
            throw DDSError.initializationError(from: .dataWriter)
        }
    }
}

extension DDSPublisher {
    @usableFromInline
    internal func publishRaw(data: UnsafeRawPointer) throws(DDSError) {
        let retcode = raw.write(data: data, params: .init())
        if let error = FastDDSErrorCode.check(retcode) {
            throw DDSError.publishError(error)
        }
    }

    @inlinable
    public func publish(_ message: borrowing T) throws(DDSError) {
        try withUnsafePointer(to: message) { messagePtr throws(DDSError) in
            try publishRaw(data: messagePtr)
        }
    }
}

extension DDSPublisher: CustomStringConvertible {
    public var description: String {
        "DDSPublisher(topic: \(topic))"
    }
}
