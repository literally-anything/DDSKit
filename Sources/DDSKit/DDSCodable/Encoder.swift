/**
 * Encoder.swift
 * DDSKit
 *
 * Created by Hunter Baker on 1/31/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */

internal import _CFastDDS

/// An encoder for encoding data to the DDS's CDR format.
public struct DDSEncoder: ~Copyable {
    /// The serializer used to encode the data.
    /// - Warning: This is an unsafe reference to the underlying CDR serializer. Lifetime must be managed in c++.
    internal var serializer: FastDDS.CDR.CDRSerializer

    /// Create a new encoder with the provided serializer.
    /// - Parameter serializer: The serializer to use to encode the data.
    /// - Warning: This is an unsafe reference to the underlying CDR serializer. Lifetime must be managed externally.
    internal init(_ serializer: FastDDS.CDR.CDRSerializer) {
        self.serializer = serializer
    }
}

extension DDSEncoder {
    /// An error that can occur when encoding data.
    public enum EncodingError: Error {
        /// There was not enough storage allocated to encode the data.
        /// This is most likely a library bug or a bug in the user's code for size calculation.
        case notEnoughStorage
    }

    /// Start encoding a new struct.
    /// - Parameter body: A closure that will be called with the encoder to encode the struct.
    /// - Throws: An error if there is not enough storage allocated to encode the struct or some other unexpected error occurs in the closure.
    public mutating func withStruct(_ body: (inout DDSEncoder) throws(EncodingError) -> Void) throws(EncodingError) {
        var state = serializer.initState()
        let success = serializer.beginStruct(state: &state)
        guard success else { throw .notEnoughStorage }

        try body(&self)

        guard serializer.endStruct(previousState: &state) else { throw .notEnoughStorage }
    }

    /// A wrapper around the state of the encoder.
    /// This is supposed to only be an internal type, so I had to make a wrapper until swift fixes borrowing in nonescaping closures.
    @usableFromInline
    internal struct StateWrapper: ~Copyable {
        /// The underlying state object.
        internal var state: FastDDS.CDR.CDRSerializer.State
        /// Create a new state wrapper with the provided state.
        @usableFromInline
        internal init(encoder: borrowing DDSEncoder) {
            state = encoder.serializer.initState()
        }
    }
}

extension DDSEncoder {
    /// Start encoding a new member of a struct.
    /// - Parameter memberId: The id of the member to encode.
    /// - Returns: The state of the encoder before the member was added.
    /// - Throws: An error if there is not enough storage allocated to encode the member.
    @usableFromInline
    internal mutating func startMember(state: inout StateWrapper, member memberId: UInt32) throws(EncodingError) {
        let success = serializer.beginMember(memberId: memberId, state: &state.state)
        guard success else { throw .notEnoughStorage }
    }

    /// End encoding a member of a struct.
    /// - Parameter previousState: The state of the encoder before the member was added.
    /// - Throws: An error if there is not enough storage allocated to encode the member.
    @usableFromInline
    internal mutating func endMember(previousState: borrowing StateWrapper) throws(EncodingError) {
        guard serializer.endMember(previousState: previousState.state) else { throw .notEnoughStorage }
    }

    /// Encode a member of a type.
    /// - Parameters:
    ///   - memberId: The id of the member to encode.
    ///   - value: The value to encode.
    /// - Throws: An error if there is not enough storage allocated to encode the member or some other unexpected error occurs during encoding.
    @inlinable
    public mutating func encode<T: DDSCodable>(member memberId: UInt32, _ value: borrowing T) throws(EncodingError) {
        var state = StateWrapper(encoder: self)

        try startMember(state: &state, member: memberId)
        try value.ddsEncode(encoder: &self)
        try endMember(previousState: state)
    }
}

extension DDSEncoder {
    /// Start encoding an optional member of a struct.
    /// - Parameters:
    ///   - memberId: The id of the member to encode.
    ///   - hasData: Whether or not the member has data.
    /// - Returns: The state of the encoder before the optional member was added.
    /// - Throws: An error if there is not enough storage allocated to encode the member.
    @usableFromInline
    internal mutating func startOptionalMember(state: inout StateWrapper, member memberId: UInt32, hasData: Bool) throws(EncodingError) {
        let success = serializer.beginOptionalMember(memberId: memberId, isPresent: hasData, state: &state.state)
        guard success else { throw .notEnoughStorage }
    }

    /// End encoding an optional member of a struct.
    /// - Parameters:
    ///   - previousState: The state of the encoder before the optional member was added.
    /// - Throws: An error if there is not enough storage allocated to encode the member.
    @usableFromInline
    internal mutating func endOptionalMember(previousState: borrowing StateWrapper) throws(EncodingError) {
        guard serializer.endOptionalMember(previousState: previousState.state) else { throw .notEnoughStorage }
    }

    /// Encode an optional member of a type.
    /// - Parameters:
    ///   - memberId: The id of the member to encode.
    ///   - value: The value to encode.
    /// - Throws: An error if there is not enough storage allocated to encode the member or some other unexpected error occurs during encoding.
    @inlinable
    public mutating func encode<T: DDSCodable>(member memberId: UInt32, _ value: borrowing T?) throws(EncodingError) {
        let hasData = value != nil
        var state = StateWrapper(encoder: self)

        try startOptionalMember(state: &state, member: memberId, hasData: hasData)
        if hasData {
            // I have to use unsafelyUnwrapped here because let bindings can't borrow for some reason.
            // ToDo: Fix this and the one in the size calculator.
            try value.unsafelyUnwrapped.ddsEncode(encoder: &self)
        }
        try endOptionalMember(previousState: state)
    }
}

extension DDSEncoder {
    /// Encode an anonymous struct member.
    /// This is mainly used for enums.
    /// - Parameters:
    ///   - memberId: The id of the member to encode.
    ///   - body: A closure that will be called with the encoder to encode the struct.
    /// - Throws: An error if there is not enough storage allocated to encode the struct or some other unexpected error occurs in the closure.
    public mutating func encodeAnonymousStruct(
        member memberId: UInt32, _ body: (inout DDSEncoder) throws(EncodingError) -> Void
    ) throws(EncodingError) {
        var state = StateWrapper(encoder: self)

        try startMember(state: &state, member: memberId)
        try withStruct(body)
        try endMember(previousState: state)
    }
}

extension DDSEncoder {
    /// Encode an entire message.
    /// This encodes an entire type that is not a member.
    /// - Parameter value: The value to encode.
    /// - Throws: An error if there is not enough storage allocated to encode the value or some other unexpected error occurs during encoding.
    @inlinable
    public mutating func encode<T: DDSCodable>(message value: borrowing T) throws(EncodingError) {
        try value.ddsEncode(encoder: &self)
    }
}
