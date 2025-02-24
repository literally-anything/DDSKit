/**
 * Publisher+RelatedMessage.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/22/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

extension DDSPublisher {
    /// Publishes a raw sample with an optional related message identifier.
    /// - Parameters:
    ///   - sample: The raw sample to publish.
    ///   - relatedIdentifier: The related message identifier. This is used to pair messages on the reciving end.
    /// - Returns: The message identifier of the published message.
    @discardableResult
    internal func publishRawWithIdentifiers(_ sample: consuming UnsafeRawPointer, related relatedIdentifier: MessageIdentifier? = nil) throws(DDSError) -> MessageIdentifier {
        var myIdentity = FastDDS.SampleIdentity()
        let retcode = raw.write(data: sample, related: relatedIdentifier.sampleIdentity, this: &myIdentity)
        if let error = FastDDSErrorCode.check(retcode) {
            throw DDSError.publishError(error)
        }
        return MessageIdentifier(myIdentity)!
    }

    /// Publishes a message with an optional related message identifier.
    /// - Parameters:
    ///   - message: The message to publish.
    ///   - relatedIdentifier: The related message identifier. This is used to pair messages on the reciving end.
    /// - Returns: The message identifier of the published message.
    @discardableResult
    public func publishWithIdentifiers(_ message: borrowing Message, related relatedIdentifier: MessageIdentifier? = nil) throws(DDSError) -> MessageIdentifier {
        try withUnsafePointer(to: message) { messagePtr throws(DDSError) in
            try publishRawWithIdentifiers(messagePtr, related: relatedIdentifier)
        }
    }
}
