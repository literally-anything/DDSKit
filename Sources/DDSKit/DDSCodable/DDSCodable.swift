/**
 * DDSCodable.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 1/23/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

/// A type that can be encoded and decoded with CDR.
public protocol DDSCodable: Sendable {
    /// Initialize the type with the default data.
    /// This is used internally to initiailize the memory for the type.
    static var ddsInitialized: Self { get }

    /// The type descriptor for the type.
    static var ddsTypeDescriptor: DDSTypeDescriptor { get }

    /// Calculate the size of the serialized data using the provided calculator.
    /// This shouldn't ever need to be called by the user, but is used internally.
    /// - Parameters:
    ///   - calculator: The calculator to use to calculate the size.
    func calculateDDSSize(calculator: inout DDSSizeCalculator)

    /// Encode the data using the provided DDS encoder.
    /// - Parameter encoder: The encoder to use to encode the data.
    /// - Throws: An error if there is not enough storage allocated to encode the data or some other unexpected error occurs.
    func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError)

    /// Decode the data using the provided DDS decoder.
    /// - Parameter decoder: The decoder to use to decode the data.
    /// - Throws: An error if the decoder reads beyond the bounds of the internal buffer, an unexpected member is encountered, or some other error occurs.
    mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError)
}

/// A type that can be encoded and decoded with CDR and can be loaned for zero copy transfer.
public protocol DDSLoaningCodable: Sendable, DDSCodable {}

public protocol DDSMessage: DDSCodable {
    /// The type support object for a topic.
    static var ddsTypeSupport: DDSTypeSupport { get }
}
