/**
 * CDRCodable.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 1/23/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

public protocol CDRCodable: Sendable {
    static var ddsTopicType: DynamicTypeDescription { get }
}

// public struct CDREncodingInfo<T: CDRCodable> {
//     internal let data: UnsafePointer<T>
//     // internal var serializedPayload = SerializedPayload_t()
// }

// public struct CDRDecodingInfo<T: CDRCodable> {
//     internal let data: UnsafeMutablePointer<T>
// }

// public protocol CDRCodable: Codable {
//     static func buildDDSDescriptor() -> DDSType.TypeIdentifier
//     init(fromCDR: borrowing CDRSerializedPayload, useXCDR2: Bool)
//     func cdrCalculateSize(memberId: UInt32, calculator: inout CDRSizeCalculator)
//     static var ddsTopicType: DDSType.TypeSupport { get }
// }


// extension UInt32: CDRCodable {
//     @inlinable
//     public static func buildDDSDescriptor() -> DDSType.TypeIdentifier {
//         let identifier = DDSType.TypeIdentifier(for: "_uint32_t")
//         guard let identifier else {
//             preconditionFailure("Failed to get XType identifiers for primitive type: UInt32")
//         }

//         // var calc = eprosima.fastcdr.CdrSizeCalculator.init(eprosima.fastcdr.XCDRv2)
//         // calc.begin_calculate_type_serialized_size(eprosima.fastcdr.PLAIN_CDR2, 0)
//         // calc.calculate_member_serialized_size(eprosima.fastcdr.MemberId, _T, Int)

//         return identifier
//     }

//     public init(fromCDR: borrowing CDRSerializedPayload, useXCDR2: Bool) {
//         fatalError("Not implemented")
//     }

//     public func cdrCalculateSize(memberId: UInt32, calculator: inout CDRSizeCalculator) {
//         calculator.size += calculator.calc.calculate_member_serialized_size(.init(memberId), self, &calculator.alignment)
//     }

//     @available(*, deprecated, message: "Primitive types cannot be used as topic types directly")
//     public static var ddsTopicType: DDSType.TypeSupport {
//         fatalError("Primitive types cannot be used as topic types directly. Wrap them in a specific CDRCodable structure.")
//     }
// }
