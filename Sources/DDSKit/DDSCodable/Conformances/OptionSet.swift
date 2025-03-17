/**
 * OptionSet.swift
 * Conformances
 * 
 * Created by Hunter Baker on 3/17/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */

public protocol DDSOptionSet: OptionSet, DDSCodable where RawValue: DDSCodable {
    /// The name that the option set will be registered under.
    static var ddsName: StaticString { get }
}

extension DDSOptionSet {
    @inlinable
    @inline(__always)
    public static var ddsInitialized: RawValue { .ddsInitialized }

    @inlinable
    @inline(__always)
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        DDSTypeBuilder(name: "\(ddsName)")
            .addMember(type: RawValue.self, name: "rawValue", memberId: 0)
            .build()
    }
    @inlinable
    @inline(__always)
    public static var ddsTypeSupport: DDSTypeSupport {
        DDSTypeSupport(
            message: Self.self,
            name: "\(ddsName)",
            isBounded: false, isPlain: false, maxSize: 16
        )
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
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(self)}

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
                var value: RawValue = .ddsInitialized
                try decoder.decode(&value)
                self = Self(rawValue: value)
            default:
                throw .unknownMember
            }
        }
    }
}
