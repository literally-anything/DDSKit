/**
 * RawRepresentable.swift
 * Conformances
 * 
 * Created by Hunter Baker on 3/17/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */

/// A protocol to automatically conform `RawRepresentable` types to `DDSCodable`.
/// This protocol is used to automatically generate the necessary serialization and deserialization code for `RawRepresentable` types.
public protocol DDSRawRepresentable: RawRepresentable where RawValue: DDSCodable {}
/// A protocol to automatically conform `OptionSet` types to `DDSCodable`.
/// This protocol is used to automatically generate the necessary serialization and deserialization code for `OptionSet` types.
public protocol DDSOptionSet: DDSRawRepresentable, OptionSet where RawValue: DDSCodable {}

extension DDSRawRepresentable {
    @inlinable
    @inline(__always)
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        RawValue.ddsTypeDescriptor
    }

    @inlinable
    @inline(__always)
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        rawValue.calculateDDSSize(calculator: &calculator)
    }

    @inlinable
    @inline(__always)
    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        try rawValue.ddsEncode(encoder: &encoder)
    }

    @inlinable
    @inline(__always)
    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        var value: RawValue = rawValue
        try value.ddsDecode(decoder: &decoder)
        guard let value = Self(rawValue: value) else {
            throw .badValue
        }
        self = value
    }
}

extension DDSOptionSet {
    @inlinable
    @inline(__always)
    public static var ddsInitialized: Self { [] }

    @inlinable
    @inline(__always)
    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        var value: RawValue = rawValue
        try value.ddsDecode(decoder: &decoder)
        self = Self(rawValue: value)
    }
}
