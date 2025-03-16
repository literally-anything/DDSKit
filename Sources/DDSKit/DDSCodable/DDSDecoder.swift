/**
 * DDSDecoder.swift
 * DDSCodable
 * 
 * Created by Hunter Baker on 3/15/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

/// A decoder for decoding data from the DDS's CDR format.
public struct DDSDecoder: ~Copyable {
    /// The deserializer used to decode the data.
    /// - Warning: This is an unsafe reference to the underlying CDR deserializer. Lifetime must be managed in c++.
    internal var deserializer: FastDDS.CDR.CDRDeserializer

    /// Create a new decoder with the provided deserializer.
    /// - Parameter deserializer: The deserializer to use to decode the data.
    /// - Warning: This is an unsafe reference to the underlying CDR deserializer. Lifetime must be managed externally.
    internal init(_ deserializer: FastDDS.CDR.CDRDeserializer) {
        self.deserializer = deserializer
    }
}

extension DDSDecoder {
    /// An error that can occur when decoding data.
    public enum DecodingError: Error {
        /// Tried to decode beyond the bounds of the internal buffer.
        /// This is most likely a library bug or an error in the header of a member in the encoded data.
        case outOfBounds
        /// The size of the member in the encoded data does not match the expected size.
        /// This is usually related to optional types or arrays.
        /// This is most likely a library bug or an error in the header of a member in the encoded data.
        case memberSizeMismatch
        /// Tried to decode a member with a header that says the size is zero.
        /// This is most likely an error in the header of a member in the encoded data or a type mismatch between the encoded and decoded data.
        case invalidMember
        /// Tried to decode a member with an unknown id.
        /// This might mean that the data is being encode as a different type than it is being decoded as.
        case unknownMember
    }

    /// Start decoding a new struct.
    /// - Parameter body: A closure that will be called for each member of the struct to decode. The closure gets passed the member id and the decoder.
    /// - Throws: `.outOfBounds` if the decoder trys to read beyond the bounds of the internal buffer or some other unexpected error if one occurs in the closure.
    public mutating func withStruct(_ body: (inout DDSDecoder, UInt32) throws(DecodingError) -> Void) throws(DecodingError) {
        // The pointer stuff in this function is a little weird, but it is necessary to get self in there.
        // This is because DDSDecoder is noncopyable and Swift can't yet verify access to self in this way.
        try withUnsafeMutablePointer(to: &self) { contextPtr throws(DecodingError) in
            var error: DecodingError?
            let ret = contextPtr.pointee.deserializer.withStruct { deserializer, memberId in
                do throws(DecodingError) {
                    try body(&contextPtr.pointee, memberId)
                } catch let e {
                    error = e
                    return false
                }
                return true
            }
            if let error {
                throw error
            } else if !ret {
                throw DecodingError.outOfBounds
            }
        }
    }
}

extension DDSDecoder {
    /// Start decoding a new member of a struct at the current position.
    /// - Parameter value: The destination for the decoded data.
    /// - Throws: An error if the member size in the encoded data does not match the expected size or some other error occurs.
    @inlinable
    public mutating func decode<T: DDSCodable>(_ value: inout T) throws(DecodingError) {
        try value.ddsDecode(decoder: &self)
    }
}

extension DDSDecoder {
    /// Setup decoding an optional member.
    /// - Throws: An error if the member size in the encoded data does not match the expected size or some other error occurs.
    @usableFromInline
    internal mutating func setupOptionalMember() throws(DecodingError) {
        guard deserializer.setupOptional() else {
            throw .invalidMember
        }
    }

    /// Deserialize the isPresent flag for an optional member.
    /// - Throws: An error if the member size in the encoded data does not match the expected size or some other error occurs.
    @usableFromInline
    internal mutating func deserializeOptionalIsPresent() throws(DecodingError) -> Bool {
        if deserializer.checkIfOptionalHasIsPresent() {
            var isPresent: Bool = false
            guard deserializer.deserialize(&isPresent) else {
                throw .outOfBounds
            }
            return isPresent
        } else {
            // Default to true if the is isPresent flag is not present
            return true
        }
    }

    /// Decode an optional member of a struct at the current position.
    /// - Parameter value: The destination for the decoded data.
    /// - Throws: An error if the member size in the encoded data does not match the expected size or some other error occurs.
    @inlinable
    public mutating func decode<T: DDSCodable>(_ value: inout T?) throws(DecodingError) {
        try setupOptionalMember()

        let isPresent = try deserializeOptionalIsPresent()
        if isPresent {
            var error: DecodingError?
            // There doesn't seem to be a way to do this without a temporary allocation because i cant set an optional using inout
            // I really don't like this and would like to find a better way to do this.
            withUnsafeTemporaryAllocation(of: T.self, capacity: 1) { ptr in
                let newValuePtr = ptr.baseAddress.unsafelyUnwrapped
                UnsafeMutableRawPointer(newValuePtr).initializeMemory(as: UInt8.self, repeating: 0, count: MemoryLayout<T>.size)
                do throws(DecodingError) {
                    try newValuePtr.pointee.ddsDecode(decoder: &self)
                } catch let e {
                    error = e
                }
                value = .init(newValuePtr.pointee)
            }
            if let error {
                throw error
            }
        } else {
            value = nil
        }
    }
}

extension DDSDecoder {
    /// Decode an entire message.
    /// This decodes an entire type that is not a member. This is only called internally when deserializing an entire message.
    /// - Parameter value: The value to decode.
    /// - Throws: An error if the decoder reads beyond the bounds of the internal buffer, an unexpected member is encountered, or some other error occurs.
    internal mutating func decode<T: DDSCodable>(message value: inout T) throws(DecodingError) {
        try value.ddsDecode(decoder: &self)
    }
}
