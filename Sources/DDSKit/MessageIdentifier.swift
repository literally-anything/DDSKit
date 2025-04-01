/**
 * MessageIdentifier.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/22/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

/// A unique identifier for a message.
/// This is used to track the message for request reply and similar patterns.
/// These are amost always passed as Optional because they are not always present.
public struct DDSMessageIdentifier: Sendable {
    /// The underlying fastdds SampleIdentity.
    internal let sampleIdentity: FastDDS.SampleIdentity

    /// The writer identifier of the message.
    /// In Fast-DDS terms, this is the writer GUID.
    public var writerIdentifier: DDSEntityIdentifier {
        .init(guid: sampleIdentity.writerGuid)
    }

    /// The sequence number of the message.
    /// This is the U64 long representation.
    public var sequenceNumber: UInt64 {
        sampleIdentity.sequenceu64Long
    }
}

extension DDSMessageIdentifier {
    /// Creates a new empty message identifier.
    public init?() {
        return nil
    }

    /// Creates a new message identifier from a fastdds SampleIdentity.
    /// - Parameter identity: The fastdds SampleIdentity.
    internal init?(_ identity: consuming FastDDS.SampleIdentity) {
        guard !identity.isUnknown else {
            return nil
        }
        sampleIdentity = identity
    }

    /// An empty message identifier.
    public var unknown: DDSMessageIdentifier? { DDSMessageIdentifier() }
}

extension DDSMessageIdentifier: Hashable {
    public static func == (lhs: DDSMessageIdentifier, rhs: DDSMessageIdentifier) -> Bool {
        lhs.sampleIdentity == rhs.sampleIdentity
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(writerIdentifier)
        hasher.combine(sampleIdentity.sequenceu64Long)
    }
}

extension Optional where Wrapped == DDSMessageIdentifier {
    /// The fastdds SampleIdentity representation of the message identifier.
    /// If the message identifier is nil, this will be an unknown() SampleIdentity.
    internal var sampleIdentity: FastDDS.SampleIdentity {
        switch (self) {
            case .none:
                .init()
            case .some(let value):
                value.sampleIdentity
        }
    }
}
