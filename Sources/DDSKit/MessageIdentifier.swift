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
public struct MessageIdentifier: Sendable {
    /// The underlying fastdds SampleIdentity.
    internal let sampleIdentity: FastDDS.SampleIdentity

    /// The high value of the message identifier.
    public var high: Int32 {
        sampleIdentity.high
    }
    /// The low value of the message identifier.
    public var low: UInt32 {
        sampleIdentity.low
    }
    /// The UInt64 representation of the identifer.
    public var full: UInt64 {
        sampleIdentity.u64Long
    }
}

extension MessageIdentifier {
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
    public var unknown: MessageIdentifier? { MessageIdentifier() }
}

extension MessageIdentifier: Hashable {
    public static func == (lhs: MessageIdentifier, rhs: MessageIdentifier) -> Bool {
        lhs.sampleIdentity == rhs.sampleIdentity
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(sampleIdentity.u64Long)
    }
}

extension Optional where Wrapped == MessageIdentifier {
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
