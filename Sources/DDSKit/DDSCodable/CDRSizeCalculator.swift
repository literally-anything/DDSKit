/**
 * CDRSizeCalculator.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 1/27/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
// internal import _CFastDDS

// public struct CDRSizeCalculator: ~Copyable {
//     internal var calc: CDR.CdrSizeCalculator
//     internal var size: Int = 0
//     internal var alignment: Int = 0

//     public struct Encoding {
//         internal let encoding: eprosima.fastcdr.EncodingAlgorithmFlag
//     }

//     internal init(useXCDR2: Bool) {
//         calc = CDR.CdrSizeCalculator(useXCDR2 ? eprosima.fastcdr.XCDRv1 : eprosima.fastcdr.XCDRv2)
//     }

//     public mutating func beginStruct() -> Encoding {
//         let previousEncoding = calc.get_encoding()

//         size += calc.begin_calculate_type_serialized_size(
//             eprosima.fastcdr.XCDRv2 == calc.get_cdr_version() ? eprosima.fastcdr.PLAIN_CDR2 : eprosima.fastcdr.PLAIN_CDR,
//             &alignment
//         )

//         return Encoding(encoding: previousEncoding)
//     }

//     public mutating func endStruct(previousEncoding: consuming Encoding) {
//         size += calc.end_calculate_type_serialized_size(previousEncoding.encoding, &alignment)
//     }

//     public mutating func add(_ memberId: UInt32, _ value: Bool) {
//         size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
//     }

//     public mutating func add(_ memberId: UInt32, _ value: Int) {
//         size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
//     }

//     public mutating func add(_ memberId: UInt32, _ value: UInt) {
//         size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
//     }

//     public mutating func add(_ memberId: UInt32, _ value: Int8) {
//         size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
//     }

//     public mutating func add(_ memberId: UInt32, _ value: UInt8) {
//         size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
//     }

//     public mutating func add(_ memberId: UInt32, _ value: Int16) {
//         size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
//     }

//     public mutating func add(_ memberId: UInt32, _ value: UInt16) {
//         size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
//     }

//     public mutating func add(_ memberId: UInt32, _ value: Int32) {
//         size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
//     }

//     public mutating func add(_ memberId: UInt32, _ value: UInt32) {
//         size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
//     }

//     public mutating func add(_ memberId: UInt32, _ value: Int64) {
//         size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
//     }

//     public mutating func add(_ memberId: UInt32, _ value: UInt64) {
//         size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
//     }

//     public mutating func add(_ memberId: UInt32, _ value: Float) {
//         size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
//     }

//     public mutating func add(_ memberId: UInt32, _ value: Double) {
//         size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
//     }

//     public mutating func add(_ memberId: UInt32, _ value: Float80) {
//         size += calc.calculate_member_serialized_size(.init(memberId), value, &alignment)
//     }

//     public mutating func add(_ memberId: UInt32, _ value: String) {
//         size += calc.calculate_member_serialized_size(.init(memberId), std.string(value), &alignment)
//     }
// }

// private final class SizeCalculatorStorage {
//     var calc: CDR.CdrSizeCalculator
//     var alignment: Int
//     var calculatedSize: Int = 4

//     init(useXCDR2: Bool, startingAlignment: Int = 0) {
//         calc = CDR.CdrSizeCalculator(
//             useXCDR2 ? eprosima.fastcdr.XCDRv1 : eprosima.fastcdr.XCDRv2
//         )
//         alignment = startingAlignment
//     }
// }

// internal struct CDRSizeCalculator: Encoder {
//     private let storage: SizeCalculatorStorage

//     internal let codingPath: [any CodingKey] = []
//     internal let userInfo: [CodingUserInfoKey : Any] = [:]

//     internal init(useXCDR2: Bool) {
//         storage = SizeCalculatorStorage(useXCDR2: useXCDR2)
//     }

//     fileprivate init(storage: SizeCalculatorStorage) {
//         self.storage = storage
//     }

//     internal func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
//         KeyedEncodingContainer<Key>.init(KeyedSizeCalculatorContainer(storage: storage))
//     }

//     internal func unkeyedContainer() -> any UnkeyedEncodingContainer {
//         UnkeyedSizeCalculatorContainer(storage: storage)
//     }

//     internal func singleValueContainer() -> any SingleValueEncodingContainer {
//         fatalError("Can't directly use single values with CDRSizeCalculator")
//     }

//     internal static func calculateSize<T: Encodable>(of value: T, useXCDR2: Bool) -> UInt32 {
//         let encoder = CDRSizeCalculator(useXCDR2: useXCDR2)
//         try! value.encode(to: encoder)
//         return UInt32(encoder.storage.calculatedSize)
//     }
// }

// internal struct KeyedSizeCalculatorContainer<Key: CodingKey> : KeyedEncodingContainerProtocol {
//     fileprivate let storage: SizeCalculatorStorage
//     private var memberId: UInt32 = 0

//     internal let codingPath: [any CodingKey] = []

//     fileprivate init(storage: SizeCalculatorStorage) {
//         self.storage = storage

//         storage.calculatedSize &+= storage.calc.begin_calculate_type_serialized_size(
//             eprosima.fastcdr.XCDRv2 == storage.calc.get_cdr_version() ? eprosima.fastcdr.PLAIN_CDR2 : eprosima.fastcdr.PLAIN_CDR,
//             &storage.alignment
//         )
//     }

//     internal mutating func superEncoder() -> any Encoder {
//         fatalError("Super encoder not implemented for CDRSizeCalculator (because it probably shouldn't be used)")
//     }

//     internal mutating func superEncoder(forKey key: Key) -> any Encoder {
//         fatalError("Super encoder not implemented for CDRSizeCalculator (because it probably shouldn't be used)")
//     }

//     internal mutating func encodeNil(forKey key: Key) {
//         fatalError("Hasnt been implemented yet")
//     }

//     internal mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
//         fatalError("Hasnt been implemented yet")
//     }

//     internal mutating func nestedUnkeyedContainer(forKey key: Key) -> any UnkeyedEncodingContainer {
//         fatalError("Hasnt been implemented yet")
//     }

//     mutating func encode(_ value: Bool, forKey key: Key) {
//         storage.calculatedSize &+= storage.calc.calculate_member_serialized_size(.init(memberId), value, &storage.alignment)
//     }

//     mutating func encode(_ value: String, forKey key: Key) {
//         fatalError("Hasnt been implemented yet")
//     }

//     mutating func encode(_ value: Double, forKey key: Key) {
//         storage.calculatedSize &+= storage.calc.calculate_member_serialized_size(.init(memberId), value, &storage.alignment)
//     }

//     mutating func encode(_ value: Float, forKey key: Key) {
//         storage.calculatedSize &+= storage.calc.calculate_member_serialized_size(.init(memberId), value, &storage.alignment)
//     }

//     mutating func encode(_ value: Int, forKey key: Key) {
//         storage.calculatedSize &+= storage.calc.calculate_member_serialized_size(.init(memberId), value, &storage.alignment)
//     }

//     mutating func encode(_ value: Int8, forKey key: Key) {
//         storage.calculatedSize &+= storage.calc.calculate_member_serialized_size(.init(memberId), value, &storage.alignment)
//     }

//     mutating func encode(_ value: Int16, forKey key: Key) {
//         storage.calculatedSize &+= storage.calc.calculate_member_serialized_size(.init(memberId), value, &storage.alignment)
//     }

//     mutating func encode(_ value: Int32, forKey key: Key) {
//         storage.calculatedSize &+= storage.calc.calculate_member_serialized_size(.init(memberId), value, &storage.alignment)
//     }

//     mutating func encode(_ value: Int64, forKey key: Key) {
//         storage.calculatedSize &+= storage.calc.calculate_member_serialized_size(.init(memberId), value, &storage.alignment)
//     }

//     @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
//     mutating func encode(_ value: Int128, forKey key: Key) throws(EncodingError) {
//         throw .invalidValue("Swift doesn't support passing Int128 or UInt128 to C++ yet", .init(codingPath: codingPath, debugDescription: ""))
//     }

//     mutating func encode(_ value: UInt, forKey key: Key) {
//         storage.calculatedSize &+= storage.calc.calculate_member_serialized_size(.init(memberId), value, &storage.alignment)
//     }

//     mutating func encode(_ value: UInt8, forKey key: Key) {
//         storage.calculatedSize &+= storage.calc.calculate_member_serialized_size(.init(memberId), value, &storage.alignment)
//     }

//     mutating func encode(_ value: UInt16, forKey key: Key) {
//         storage.calculatedSize &+= storage.calc.calculate_member_serialized_size(.init(memberId), value, &storage.alignment)
//     }

//     mutating func encode(_ value: UInt32, forKey key: Key) {
//         storage.calculatedSize &+= storage.calc.calculate_member_serialized_size(.init(memberId), value, &storage.alignment)
//     }

//     mutating func encode(_ value: UInt64, forKey key: Key) {
//         storage.calculatedSize &+= storage.calc.calculate_member_serialized_size(.init(memberId), value, &storage.alignment)
//     }

//     @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
//     mutating func encode(_ value: UInt128, forKey key: Key) throws(EncodingError) {
//         throw .invalidValue("Swift doesn't support passing Int128 or UInt128 to C++ yet", .init(codingPath: codingPath, debugDescription: ""))
//     }

//     mutating func encode<T>(_ value: T, forKey key: Key) where T : Encodable {
//         fatalError("Hasnt been implemented yet")
//     }
// }

// internal struct UnkeyedSizeCalculatorContainer: UnkeyedEncodingContainer {
//     fileprivate let storage: SizeCalculatorStorage

//     internal var codingPath: [any CodingKey] = []

//     internal var count: Int = 0

//     internal mutating func superEncoder() -> any Encoder {
//         fatalError("Super encoder not implemented for CDRSizeCalculator (because it probably shouldn't be used)")
//     }

//     internal mutating func encodeNil() {
//         fatalError("Hasnt been implemented yet")
//     }

//     internal mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
//         fatalError("Hasnt been implemented yet")
//     }

//     internal mutating func nestedUnkeyedContainer() -> any UnkeyedEncodingContainer {
//         fatalError("Hasnt been implemented yet")
//     }

//     internal mutating func encode<T>(_ value: T) throws(EncodingError) {
//         throw .invalidValue(
//             "Cannot encode single value in UnkeyedSizeCalculatorContainer",
//             .init(codingPath: codingPath, debugDescription: "")
//         )
//     }

//     internal mutating func encode<T>(contentsOf sequence: T) where T : Sequence {
//         fatalError("Hasnt been implemented yet")
//     }
// }
