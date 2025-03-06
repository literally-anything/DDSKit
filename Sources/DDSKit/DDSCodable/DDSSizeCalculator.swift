/**
 * CDRSizeCalculator.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 1/27/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

public struct DDSSizeCalculator: ~Copyable {
    internal var calc: FastDDS.CDR.CdrSizeCalculator
    internal var size: Int = 0
    internal var alignment: Int = 0

    public struct Encoding {
        internal let encoding: eprosima.fastcdr.EncodingAlgorithmFlag
    }

    internal init(useXCDR2: Bool = true) {
        calc = FastDDS.CDR.CdrSizeCalculator(useXCDR2 ? eprosima.fastcdr.XCDRv1 : eprosima.fastcdr.XCDRv2)
    }

    public mutating func beginStruct() -> Encoding {
        let previousEncoding = calc.get_encoding()

        size += calc.begin_calculate_type_serialized_size(
            eprosima.fastcdr.XCDRv2 == calc.get_cdr_version() ? eprosima.fastcdr.PLAIN_CDR2 : eprosima.fastcdr.PLAIN_CDR,
            &alignment
        )

        return Encoding(encoding: previousEncoding)
    }

    public mutating func endStruct(previousEncoding: consuming Encoding) {
        size += calc.end_calculate_type_serialized_size(previousEncoding.encoding, &alignment)
    }

    public mutating func add(member memberId: UInt32, _ value: Bool) {
        size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
    }

    public mutating func add(member memberId: UInt32, _ value: Int) {
        size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
    }

    public mutating func add(member memberId: UInt32, _ value: UInt) {
        size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
    }

    public mutating func add(member memberId: UInt32, _ value: Int8) {
        size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
    }

    public mutating func add(member memberId: UInt32, _ value: UInt8) {
        size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
    }

    public mutating func add(member memberId: UInt32, _ value: Int16) {
        size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
    }

    public mutating func add(member memberId: UInt32, _ value: UInt16) {
        size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
    }

    public mutating func add(member memberId: UInt32, _ value: Int32) {
        size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
    }

    public mutating func add(member memberId: UInt32, _ value: UInt32) {
        size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
    }

    public mutating func add(member memberId: UInt32, _ value: Int64) {
        size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
    }

    public mutating func add(member memberId: UInt32, _ value: UInt64) {
        size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
    }

    public mutating func add(member memberId: UInt32, _ value: Float) {
        size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
    }

    public mutating func add(member memberId: UInt32, _ value: Double) {
        size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
    }

    public mutating func add(member memberId: UInt32, _ value: Float80) {
        size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
    }

    public mutating func add(member memberId: UInt32, _ value: String) {
        size += calc.calculate_member_serialized_size(.init(memberId), std.string(value), &alignment)
    }
}
