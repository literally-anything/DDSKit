/**
 * TypeSupport.swift
 * DDSCodable
 * 
 * Created by Hunter Baker on 3/16/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS
internal import Logging

/// Type support functionality for a topic. Represents the underlying FastDDS `TypeSupport` object.
public struct DDSTypeSupport: Sendable {
    /// The logger for the type support.
    /// This is used for logging about encoding, decoding, and initialization errors.
    private static let logger = Logger(label: "DDSKit.DDSTypeSupport")

    /// The underlying FastDDS `TypeSupport` object.
    internal let typeSupport: FastDDS.Types.TypeSupport

    /// Creates a new topic type support object with the given name and type descriptor.
    /// This function sets isBounded, isPlain, and maxSize automatically based on the type descriptor.
    /// - Parameters:
    ///   - name: The name of the type. This must be unique and the same as the name on the other end.
    ///   - type: The type of the message. This must be a `DDSCodable` type.
    @inlinable
    @inline(__always)
    public init<Message: DDSCodable>(
        name: String,
        type: Message.Type
    ) {
        /// Just used so the value is copied when used in createType, and the type descriptor can be deallocated.
        let isPlain = Message.ddsTypeDescriptor.isPlain

        self.init(name: name, type: type, isBounded: Message.ddsTypeDescriptor.isBounded, isPlain: isPlain, maxSize: UInt32(Message.ddsTypeDescriptor.maxSize))
    }

    /// Creates a new topic type support object with the given name and type descriptor.
    /// This function allows you to manually specify whether the type is bounded or unbounded, plain or not, and the maximum size of the type.
    /// - Parameters:
    ///   - name: The name of the type. This must be unique and the same as the name on the other end.
    ///   - type: The type of the message. This must be a `DDSCodable` type.
    ///   - isBounded: Whether the type is bounded or unbounded. Defaults to `false`.
    ///   - isPlain: Whether the serialization is plain or not (can be loaned). Defaults to `false`.
    ///   - maxSize: The maximum size of the type.
    @inlinable
    @inline(__always)
    public init<Message: DDSCodable>(
        name: String,
        type: Message.Type,
        isBounded: Bool = false, isPlain: Bool = false, maxSize: UInt32
    ) {
        self.init(
            name: name,
            isBounded: isBounded, isPlain: isPlain, maxSize: maxSize
        ) {
            Message.ddsTypeDescriptor
        } createType: {
            let data = UnsafeMutablePointer<Message>.allocate(capacity: 1)
            if !isPlain {
                data.initialize(to: .ddsInitialized)
            }
            return .init(data)
        } deleteType: { data in
            data.deallocate()
        } initializeType: { data in
            data.assumingMemoryBound(to: Message.self).initialize(to: .ddsInitialized)
            return true
        } serialize: { data, encoder throws(DDSEncoder.EncodingError) in
            let typedData = data.assumingMemoryBound(to: Message.self)
            try typedData.pointee.ddsEncode(encoder: &encoder)
        } deserialize: { data, decoder throws(DDSDecoder.DecodingError) in
            let typedData = data.assumingMemoryBound(to: Message.self)
            try typedData.pointee.ddsDecode(decoder: &decoder)
        } calculateSize: { data, useXCDR2 in
            let typedData = data.assumingMemoryBound(to: Message.self)
            return DDSSizeCalculator.calculateSize(typedData.pointee, useXCDR2: useXCDR2)
        }
    }

    /// Creates a new topic type support object with the given name and type descriptor.
    /// This function exposes all of the underlying functions and parameters in the FastDDS `TypeSupport` object.
    /// - Note: This function is used for advanced use cases where you need to manually specify the type support functions. For most cases just use `.init(name:type:)`.
    /// - Parameters:
    ///   - name: The name of the type. This must be unique and the same as the name on the other end.
    ///   - isBounded: Whether the type is bounded or unbounded. Defaults to `false`.
    ///   - isPlain: Whether the serialization is plain or not (can be loaned). Defaults to `false`.
    ///   - maxSize: The maximum size of the type.
    ///   - registerType: A closure that returns the type descriptor for the type.
    ///   - createType: A closure that creates the type. (Allocates memory for it)
    ///   - deleteType: A closure that deletes the type. (Deallocates memory for it)
    ///   - initializeType: A closure that initializes the type. (Initializes memory in-place)
    ///   - serialize: A closure that serializes the type.
    ///   - deserialize: A closure that deserializes the type.
    ///   - calculateSize: A closure that calculates the size of the type.
    public init(
        name: String,
        isBounded: Bool = false, isPlain: Bool = false, maxSize: UInt32 = 0,
        registerType: @escaping @Sendable () -> DDSTypeDescriptor,
        createType: @escaping @Sendable () -> UnsafeMutableRawPointer,
        deleteType: @escaping @Sendable (UnsafeMutableRawPointer) -> Void,
        initializeType: @escaping @Sendable (UnsafeMutableRawPointer) -> Bool,
        serialize: @escaping @Sendable (UnsafeRawPointer, inout DDSEncoder) throws(DDSEncoder.EncodingError) -> Void,
        deserialize: @escaping @Sendable (UnsafeMutableRawPointer, inout DDSDecoder) throws(DDSDecoder.DecodingError) -> Void,
        calculateSize: @escaping @Sendable (UnsafeRawPointer, Bool) -> UInt32
    ) {
        let topicType = FastDDS.GenericTopicType(
            name: .init(name),
            isBounded: isBounded, isPlain: isPlain, maxSize: maxSize
        ) {
            registerType().identifier
        } create: {
            createType()
        } destroy: { data in
            deleteType(data)
        } construct: { data in
            initializeType(data)
        } serialize: { data, serializer in
            var encoder = DDSEncoder(serializer)
            do {
                try serialize(data, &encoder)
            } catch {
                DDSTypeSupport.logger.error("Failed to serialize \(name): \(error)")
                return false
            }
            return true
        } deserialize: { data, deserializer in
            var decoder = DDSDecoder(deserializer)
            do {
                try deserialize(data, &decoder)
            } catch {
                DDSTypeSupport.logger.error("Failed to deserialize \(name): \(error)")
                return false
            }
            return true
        } calculateSize: { data, useXCDR2 in
            calculateSize(data, useXCDR2)
        }

        typeSupport = topicType.typeSupport
    }
}
