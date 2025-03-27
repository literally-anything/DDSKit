/**
 * RawRepresentable.swift
 * Conformances
 * 
 * Created by Hunter Baker on 3/17/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */

/// A protocol to automatically conform `RawRepresentable` types to `DDSCodable`.
/// This protocol is used to automatically generate the necessary serialization and deserialization code for `RawRepresentable` types.
public protocol DDSRawRepresentable: RawRepresentable, DDSMessage where RawValue: DDSCodable {
    /// The name that the dds type will be registered under.
    static var ddsName: String { get }
}
/// A protocol to automatically conform `OptionSet` types to `DDSCodable`.
/// This protocol is used to automatically generate the necessary serialization and deserialization code for `OptionSet` types.
public protocol DDSOptionSet: DDSRawRepresentable, OptionSet, DDSMessage where RawValue: DDSCodable {}

extension DDSRawRepresentable {
    @inlinable
    @inline(__always)
    public static var ddsName: String { "\(Self.self): Swift.RawRepresentable" }

    @inlinable
    @inline(__always)
    public static var ddsInitialized: RawValue { .ddsInitialized }

    @inlinable
    @inline(__always)
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        DDSTypeDescriptor(struct: ddsName) { builder in
            builder.addMember(type: RawValue.self, name: "rawValue", memberId: 0)
        }
    }

    @inlinable
    @inline(__always)
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        calculator.withStruct { calculator in
            calculator.add(member: 0, rawValue)
        }
    }

    @inlinable
    @inline(__always)
    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        try encoder.withStruct { encoder throws(DDSEncoder.EncodingError) in
            try encoder.encode(member: 0, rawValue)
        }
    }

    @inlinable
    @inline(__always)
    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        try decoder.withStruct { decoder, memberId throws(DDSDecoder.DecodingError) in
            switch memberId {
            case 0:
                var value: RawValue = rawValue
                try decoder.decode(&value)
                guard let value = Self(rawValue: value) else {
                    throw .badValue
                }
                self = value
            default:
                throw .unknownMember
            }
        }
    }
}

extension DDSOptionSet {
    @inlinable
    @inline(__always)
    public static var ddsName: String { "\(Self.self): Swift.OptionSet" }

    @inlinable
    @inline(__always)
    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        try decoder.withStruct { decoder, memberId throws(DDSDecoder.DecodingError) in
            switch memberId {
            case 0:
                var value: RawValue = rawValue
                try decoder.decode(&value)
                self = Self(rawValue: value)
            default:
                throw .unknownMember
            }
        }
    }
}
