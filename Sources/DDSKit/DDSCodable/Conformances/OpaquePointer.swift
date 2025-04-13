/**
 * OpaquePointer.swift
 * Conformances
 *
 * Created by Hunter Baker on 4/04/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */

// This can't be directly DDSCodable because pointer types are not Sendable.
// When using this, you should wrap it in an @uncheked Sendable type and pass calls through to these functions.

extension OpaquePointer {
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        UInt.ddsTypeDescriptor
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        UInt(bitPattern: self).calculateDDSSize(calculator: &calculator)
    }

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        try UInt(bitPattern: self).ddsEncode(encoder: &encoder)
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        var value = UInt(bitPattern: self)
        try value.ddsDecode(decoder: &decoder)
        self = OpaquePointer(bitPattern: value)!
    }
}

extension DDSSizeCalculator {
    /// Adds an unsafe OpaquePointer member to the size calculator.
    /// - Warning: This is unsafe because the receiver may not be on the same computer as the sender and the pointer may not be valid.
    /// - Parameters:
    ///   - memberId: The ID of the member.
    ///   - pointer: The pointer to add.
    public mutating func add(member memberId: UInt32, unsafe pointer: OpaquePointer) {
        self.add(member: memberId, UInt())
    }
}

extension DDSEncoder {
    /// Encodes an unsafe OpaquePointer.
    /// - Warning: This is unsafe because the receiver may not be on the same computer as the sender and the pointer may not be valid.
    /// - Parameters:
    ///   - memberId: The ID of the member.
    ///   - pointer: The pointer to encode.
    /// - Throws: If the pointer cannot be encoded.
    public mutating func encode(member memberId: UInt32, unsafe pointer: OpaquePointer) throws(DDSEncoder.EncodingError) {
        try self.encode(member: memberId, UInt(bitPattern: pointer))
    }
}

extension DDSDecoder {
    /// Decodes an unsafe OpaquePointer.
    /// - Warning: This is unsafe because the receiver may not be on the same computer as the sender and the pointer may not be valid.
    /// - Parameter pointer: The pointer to decode.
    /// - Throws: If the pointer cannot be decoded.
    public mutating func decode(unsafe pointer: inout OpaquePointer) throws(DDSDecoder.DecodingError) {
        var value = UInt()
        try decode(&value)
        pointer = OpaquePointer(bitPattern: value)!
    }
}
