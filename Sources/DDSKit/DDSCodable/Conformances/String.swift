/**
 * String.swift
 * Conformances
 *
 * Created by Hunter Baker on 3/15/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */

internal import _CFastDDS

extension String: DDSCodable {
    public static var ddsInitialized: String { .init() }

    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        // Lock the building process to avoid data races, but no need to lock if the task we are running on is already building this type.
        if !DDSTypeDescriptor.isBuilding { DDSTypeDescriptor.lock.wait() }
        defer { if !DDSTypeDescriptor.isBuilding { DDSTypeDescriptor.lock.signal() } }
        return DDSTypeDescriptor.$isBuilding.withValue(true) {
            let typeName: String = "anonymous_string_unbounded"
            var identifier = FastDDS.Types.TypeIdentifierPair()

            // When in debug mode, we always build the type, so we can ensure that the type is same as the one that is already registered.
            var foundExistingType = false
            #if !DEBUG
                foundExistingType = FastDDS.Types.getIdentifiersForName(name: .init(typeName), identifiers: &identifier)
            #endif

            // If the type is not found, we need to build it.
            if !foundExistingType {
                let ret = FastDDS.Types.createString(name: .init(typeName), isWide: false, identifiers: &identifier)
                guard ret else {
                    fatalError("Failed to build DDS string type: \(typeName). Another type with the same name already exists.")
                }
            }

            return DDSTypeDescriptor(
                identifier: identifier, name: typeName,
                isBounded: false, isPlain: false
            ) { alignment in
                4 + DDSSizeCalculator.getAlignment(currentAlignment: alignment, dataSize: 4) + 256
            }
        }
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = 4 + DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4) + utf8.count + 1
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize

        calculator.serializedSequenceMemberSize = .SERIALIZED_MEMBER_SIZE
    }

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        let success = withCString { cString in
            return encoder.serializer.serialize(string: cString)
        }
        guard success else { throw .notEnoughStorage }
    }
    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        var length: UInt32 = 0
        let success = decoder.deserializer.deserialize(&length)
        guard success else { throw .outOfBounds }

        if length == 0 {
            removeAll()
            return
        }
        guard decoder.deserializer.sizeRemaining >= length else { throw .outOfBounds }

        // Save last datasize.
        decoder.deserializer.lastDataSize = MemoryLayout<CChar>.size

        assert(
            UnsafeRawBufferPointer(start: decoder.deserializer.currentOffset, count: Int(length)).last == 0,
            "DDSKit: String is not null terminated"
        )

        /// Copy the string into a swift String and advance the offset past the it.
        self = .init(cString: decoder.deserializer.currentOffset.assumingMemoryBound(to: CChar.self))
        decoder.deserializer.unsafeIncrementOffset(length)
    }
}
