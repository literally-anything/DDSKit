/**
 * DDSTypeRepresentation.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 1/25/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
// internal import _CFastDDS

// public enum DDSType {
//     public struct TypeIdentifier {
//         internal var pair: XTypes.TypeIdentifierPair

//         internal init(pair wrapper: consuming XTypes.TypeIdentifierPairWrapper) {
//             self.pair = wrapper.pair
//         }

//         public init() {
//             pair = XTypes.TypeIdentifierPairWrapper().pair
//         }

//         public init?(for name: String) {
//             self.init()
//             if !XTypes.getIdentifiers(name: .init(name), identifiers: &pair) {
//                 return nil
//             }
//         }
//     }

//     public struct TypeCreateInfo {
//         internal var info = XTypes.CreateInfo()
//         internal var memberId: UInt32 = 0

//         public init(name: String) {
//             XTypes.createStruct(info: &info, name: .init(name))
//         }

//         public mutating func addMember(name: String, identifier: TypeIdentifier, isOptional: Bool = false, isKey: Bool = false) {
//             XTypes.addStructMember(
//                 info: &info,
//                 identifiers: identifier.pair,
//                 name: .init(name),
//                 id: memberId,
//                 isOptional: isOptional, isKey: isKey
//             )
//             memberId += 1
//         }

//         public func finish() -> TypeIdentifier {
//             var identifier = TypeIdentifier()
//             XTypes.finishAndRegisterStruct(info: info, identifiers: &identifier.pair)
//             return identifier
//         }
//     }

//     public struct TopicType {
//         internal let type: GenericTopicType

//         internal init(
//             name: String,
//             hasComputeKey: Bool,
//             isBounded: Bool, isPlain: Bool, contructSample: Bool,
//             maxKeySize: UInt32,
//             maxSize: UInt32,
//             registerType: @escaping @Sendable (inout TypeIdentifier) -> Void,
//             serialize: @escaping @Sendable (UnsafeRawPointer) -> Bool,
//             deserialize: @escaping @Sendable (UnsafeRawPointer) -> Bool,
//             calculateSize: @escaping @Sendable (UnsafeRawPointer) -> UInt32,
//             // computeKey: @escaping @Sendable () -> Void,
//             create: @escaping @Sendable () -> UnsafeMutableRawPointer,
//             destroy: @escaping @Sendable (UnsafeMutableRawPointer) -> Void
//         ) {
//             type = GenericTopicType(
//                 name: .init(name),
//                 hasComputeKey: hasComputeKey,
//                 isBounded: isBounded, isPlain: isPlain, contructSample: contructSample,
//                 maxKeySize: maxKeySize,
//                 maxSize: maxSize
//             ) { identifiers in
//                 var identifier = TypeIdentifier(pair: .init(identifiers.pointee))
//                 registerType(&identifier)
//                 identifiers.pointee = identifier.pair
//             } serialize: { data, _, _ in
//                 if let data {
//                     return serialize(data)
//                 } else {
//                     assertionFailure("Serialize called with a nullptr data pointer")
//                     return false
//                 }
//             } deserialize: { _, data in
//                 if let data {
//                     return serialize(data)
//                 } else {
//                     assertionFailure("Deserialize called with a nullptr data pointer")
//                     return false
//                 }
//             } calculateSize: { data, _ in
//                 if let data {
//                     return calculateSize(data)
//                 } else {
//                     assertionFailure("Calculate size called with a nullptr data pointer")
//                     return 0
//                 }
//             } computeKey: { _, _, _ in
//                 return false
//             } create: {
//                 create()
//             } destroy: { data in
//                 if let data {
//                     destroy(data)
//                 } else {
//                     assertionFailure("Destroy called with a nullptr data pointer")
//                 }
//             }
//         }
//     }

//     public struct TypeSupport: CustomStringConvertible {
//         internal let typeSupport: TypeSupportWrapper

//         internal init(_ type: consuming TopicType) {
//             typeSupport = GenericTopicType.getTypeSupport(type.type)
//         }

//         public var name: String {
//             .init(typeSupport.getName())
//         }

//         public var description: String {
//             "TypeSupport(name: \(name))"
//         }
//     }
// }
