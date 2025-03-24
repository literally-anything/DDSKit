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

    /// Creates a new topic type support object.
    /// - Parameter typeSupport: The underlying FastDDS `TypeSupport` object.
    // internal init(typeSupport: FastDDS.Types.TypeSupport) {
    //     self.typeSupport = typeSupport
    // }

    @inlinable
    @inline(__always)
    public init<Message: DDSCodable>(
        message: Message.Type,
        name: String,
        isBounded: Bool = false, isPlain: Bool = false, maxSize: UInt32 = 0
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
