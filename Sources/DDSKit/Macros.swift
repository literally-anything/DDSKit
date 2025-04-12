/**
 * Macros.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 4/07/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */

/// A macro that ignores the declaration it is applied to.
/// This makes @DDSMessage not encode or decode the member.
/// This doesn't actually do anything, it's just used as a marker of ignored members.
@attached(peer)
public macro DDSIgnored() = #externalMacro(module: "DDSKitMacros", type: "IgnoredMacro")

/// A macro that automatically conforms a type to `DDSCodable`, `DDSLoaningCodable`, and `DDSMessage`.
/// It generates the required methods and properties for the type to be used with DDSKit.
/// 
/// This will not include static members, computed properties, or constants.
/// This will ignore any members that are marked with `@DDSIgnored`.
///
/// It automatically generates the `ddsInitialized` using a default constructor if one exists or is implicit.
/// If there is no default constructor, a manual `ddsInitialized` must be provided.
///
/// If the type has no ignored stored members and all members are primitive types, this will automatically conform to `DDSLoaningCodable`.
///
/// - Parameters:
///   - name: The name of the type in the DDS. This must be the same on all remote participants. If `nil`, the name of the type will be used.
///   - onlyCodable: If `true`, the type will only conform to `DDSCodable` and `DDSLoaningCodable` and not `DDSMessage`. This is for types that are not direcly sent.
@attached(
    member,
    names: named(ddsInitialized), named(ddsTypeSupport), named(ddsTypeDescriptor),
           named(calculateDDSSize), named(ddsEncode), named(ddsDecode)
)
@attached(extension, conformances: DDSCodable, DDSLoaningCodable, DDSMessage)
public macro DDSMessage(name: String? = nil, onlyCodable: Bool = false) = #externalMacro(module: "DDSKitMacros", type: "MessageMacro")

/// A macro that automatically conforms an enum to `DDSCodable` and `DDSLoaningCodable`.
/// It generates the required methods and properties for the enum to be used with DDSKit.
///
/// This will only include enum cases and their associated values.
/// It will not include static members, computed properties, or constants.
/// `@DDSIgnored` has no effect on enum cases.
///
/// It automatically generates the `ddsInitialized` using a default constructor if one exists.
/// If there is no default constructor, a manual `ddsInitialized` must be provided.
///
/// If the enum has a primitive RawValue, this will automatically conform to `DDSLoaningCodable`.
///
/// - Parameters:
///   - name: The name of the type in the DDS. This must be the same on all remote participants. If `nil`, the name of the type will be used.
/// - Note: When the enum is RawRepresentable, the name and descriptor of the RawValue type is used instead, so `name` is ignored.
///
/// - Warning: Enums without a raw value type will not be supported yet. They must be conformed manually.
@attached(
    member,
    names: named(ddsInitialized), named(ddsTypeDescriptor),
           named(calculateDDSSize), named(ddsEncode), named(ddsDecode)
)
@attached(extension, conformances: DDSRawRepresentable, DDSCodable, DDSLoaningCodable)
public macro DDSEnum(name: String? = nil) = #externalMacro(module: "DDSKitMacros", type: "EnumMacro")
