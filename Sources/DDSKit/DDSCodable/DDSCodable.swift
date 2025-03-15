/**
 * CDRCodable.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 1/23/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

/// A type that can be encoded and decoded with CDR.
public protocol DDSCodable: Sendable {
    /// The type identifier for the type.
    static var ddsTopicType: DynamicTypeDescription { get }

    /// Calculate the size of the serialized data using the provided calculator.
    /// This shouldn't ever need to be called by the user, but is used internally.
    /// - Parameters:
    ///   - calculator: The calculator to use to calculate the size.
    func calculateDDSSize(calculator: inout DDSSizeCalculator)
    /// Get the size of the serialized data using the default calculator.
    /// This may be only computed once and cached if the data type is statically sized.
    var ddsSize: UInt32 { get }

    /// Encode the data using the provided DDS encoder.
    /// - Parameter encoder: The encoder to use to encode the data.
    func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError)
}

extension DDSCodable {
    public static var ddsTopicType: DynamicTypeDescription {fatalError()}
    public var ddsSize: UInt32 {
        DDSSizeCalculator.calculateSize(self)
    }
}

/// A type that can be encoded and decoded with CDR and can be loaned for zero copy transfer.
public protocol DDSLoaningCodable: Sendable, DDSCodable {}
