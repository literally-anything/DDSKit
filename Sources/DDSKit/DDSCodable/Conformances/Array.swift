/**
 * Array.swift
 * Conformances
 * 
 * Created by Hunter Baker on 3/25/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

@usableFromInline
internal func withDDSSizeCalculatorComplexSequence(
    calculator: inout DDSSizeCalculator, length: UInt32,
    body: (inout DDSSizeCalculator) -> Void
) {
    let initialAlignment = calculator.alignment

    if calculator.calc.get_cdr_version() == eprosima.fastcdr.XCDRv2 {
        // DHEADER
        calculator.alignment += 4 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
    }

    calculator.alignment += 4 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
    calculator.size += calculator.alignment &- initialAlignment

    body(&calculator)

    if calculator.calc.get_cdr_version() == eprosima.fastcdr.XCDRv2 {
        // Inform DHEADER can be joined with NEXTINT
        calculator.serializedSequenceMemberSize = .SERIALIZED_MEMBER_SIZE;
    }
}
@usableFromInline
internal func withDDSEncoderComplexSequence(
    encoder: inout DDSEncoder, length: UInt32,
    body: (inout DDSEncoder) throws(DDSEncoder.EncodingError) -> Void
) throws(DDSEncoder.EncodingError) {
    var state = encoder.serializer.initState()
    encoder.serializer.beginSequence(state: &state)

    guard encoder.serializer.serialize(length) else {
        throw .notEnoughStorage
    }

    try body(&encoder)

    encoder.serializer.endSequence(previousState: state)
}
@usableFromInline
internal func decodeAndCheckDDSSequenceLength(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) -> UInt32 {
    var length: UInt32 = 0
    guard decoder.deserializer.deserialize(&length) else {
        throw .outOfBounds
    }
    guard decoder.deserializer.sizeRemaining >= length else {
        throw .outOfBounds
    }
    return length
}

extension Array: DDSCodable where Element: DDSCodable {
    @inlinable
    public static var ddsInitialized: Array<Element> { .init() }

    @inlinable
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        DDSTypeDescriptor.array(of: Element.ddsTypeDescriptor)
    }

    @inlinable
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        withDDSSizeCalculatorComplexSequence(calculator: &calculator, length: UInt32(count)) { calculator in
            for element in self {
                element.calculateDDSSize(calculator: &calculator)
            }
        }
    }

    @inlinable
    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        try withDDSEncoderComplexSequence(encoder: &encoder, length: UInt32(count)) { encoder throws(DDSEncoder.EncodingError) in
            for element in self {
                try element.ddsEncode(encoder: &encoder)
            }
        }
    }

    @inlinable
    internal mutating func reserveLengthDDSDecode(length: UInt32) {
        if length == 0 {
            removeAll(keepingCapacity: true)
        } else if length > capacity {
            // Reallocate the entire array because it is most likely a just as fast as reserving more space.
            self = .init(repeating: .ddsInitialized, count: Int(length))
        } else {
            removeLast(capacity - Int(length))
        }
    }
    @inlinable
    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        let length = try decodeAndCheckDDSSequenceLength(decoder: &decoder)

        reserveLengthDDSDecode(length: length)

        var error: DDSDecoder.DecodingError? = nil
        withUnsafeMutableBufferPointer { bufferPtr in
            let ptr = bufferPtr.baseAddress.unsafelyUnwrapped // This should always be defined because we reserved capacity above.
            do throws(DDSDecoder.DecodingError) {
                for i in 0..<Int(length) {
                    try ptr[i].ddsDecode(decoder: &decoder)
                }
            } catch let e {
                error = e
            }
        }
        if let error {
            throw error
        }
    }
}

/// Specific specializations for primitive types.
/// There needs to be this much duplication because the specializations in c++ have no connection to any Swift protocols I make.
/// This makes Swift complain because not every type that could conform to the protocol can be passed to an overload of the c++ function.

private func addPrimitiveHeaderSize(calculator: inout DDSSizeCalculator) {
    let initialAlignment = calculator.alignment
    calculator.alignment += 4 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
    calculator.size += calculator.alignment &- initialAlignment
}
private func setSerializedMemberSize(calculator: inout DDSSizeCalculator, size: FastDDS.CDR.SerializedMemberSizeForNextInt) {
    if calculator.calc.get_cdr_version() == eprosima.fastcdr.XCDRv2 {
        // Inform DHEADER can be joined with NEXTINT
        calculator.serializedSequenceMemberSize = size
    }
}
private func setSerializedMemberSize(encoder: inout DDSEncoder, size: FastDDS.CDR.SerializedMemberSizeForNextInt) {
    if encoder.serializer.cdrVersion == eprosima.fastcdr.XCDRv2 {
        encoder.serializer.serializedMemberSize = size
    }
}

extension Array where Element == Bool {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = count &+ 4 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize
    }

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(UInt32(count)) else {
            throw .notEnoughStorage
        }
        let success = withUnsafeBufferPointer { bufferPtr in
            encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
        }
        guard success else {
            throw .notEnoughStorage
        }
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        let length = try decodeAndCheckDDSSequenceLength(decoder: &decoder)

        reserveLengthDDSDecode(length: length)

        reserveCapacity(Int(length))
        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}
extension Array where Element == Int8 {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        addPrimitiveHeaderSize(calculator: &calculator)

        calculator.alignment += count
        calculator.size += count

        setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE)
    }

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(UInt32(count)) else {
            throw .notEnoughStorage
        }
        let success = withUnsafeBufferPointer { bufferPtr in
            encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
        }
        guard success else {
            throw .notEnoughStorage
        }
        setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE)
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        let length = try decodeAndCheckDDSSequenceLength(decoder: &decoder)

        reserveLengthDDSDecode(length: length)

        reserveCapacity(Int(length))
        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}
extension Array where Element == UInt8 {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        addPrimitiveHeaderSize(calculator: &calculator)

        calculator.alignment += count
        calculator.size += count

        setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE)
    }

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(UInt32(count)) else {
            throw .notEnoughStorage
        }
        let success = withUnsafeBufferPointer { bufferPtr in
            encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
        }
        guard success else {
            throw .notEnoughStorage
        }
        setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE)
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        let length = try decodeAndCheckDDSSequenceLength(decoder: &decoder)

        reserveLengthDDSDecode(length: length)

        reserveCapacity(Int(length))
        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}

extension Array where Element == Int16 {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        addPrimitiveHeaderSize(calculator: &calculator)

        let calculatedSize = (count &* 2) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 2)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize

        setSerializedMemberSize(calculator: &calculator, size: .NO_SERIALIZED_MEMBER_SIZE)
    }

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(UInt32(count)) else {
            throw .notEnoughStorage
        }
        let success = withUnsafeBufferPointer { bufferPtr in
            encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
        }
        guard success else {
            throw .notEnoughStorage
        }
        setSerializedMemberSize(encoder: &encoder, size: .NO_SERIALIZED_MEMBER_SIZE)
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        let length = try decodeAndCheckDDSSequenceLength(decoder: &decoder)

        reserveLengthDDSDecode(length: length)

        reserveCapacity(Int(length))
        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}
extension Array where Element == UInt16 {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        addPrimitiveHeaderSize(calculator: &calculator)

        let calculatedSize = (count &* 2) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 2)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize

        setSerializedMemberSize(calculator: &calculator, size: .NO_SERIALIZED_MEMBER_SIZE)
    }

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(UInt32(count)) else {
            throw .notEnoughStorage
        }
        let success = withUnsafeBufferPointer { bufferPtr in
            encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
        }
        guard success else {
            throw .notEnoughStorage
        }
        setSerializedMemberSize(encoder: &encoder, size: .NO_SERIALIZED_MEMBER_SIZE)
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        let length = try decodeAndCheckDDSSequenceLength(decoder: &decoder)

        reserveLengthDDSDecode(length: length)

        reserveCapacity(Int(length))
        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}

extension Array where Element == Int32 {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        addPrimitiveHeaderSize(calculator: &calculator)

        let calculatedSize = (count &* 4) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize

        setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE_4)
    }

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(UInt32(count)) else {
            throw .notEnoughStorage
        }
        let success = withUnsafeBufferPointer { bufferPtr in
            encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
        }
        guard success else {
            throw .notEnoughStorage
        }
        setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE_4)
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        let length = try decodeAndCheckDDSSequenceLength(decoder: &decoder)

        reserveLengthDDSDecode(length: length)

        reserveCapacity(Int(length))
        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}
extension Array where Element == UInt32 {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        addPrimitiveHeaderSize(calculator: &calculator)

        let calculatedSize = (count &* 4) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize

        setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE_4)
    }

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(UInt32(count)) else {
            throw .notEnoughStorage
        }
        let success = withUnsafeBufferPointer { bufferPtr in
            encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
        }
        guard success else {
            throw .notEnoughStorage
        }
        setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE_4)
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        let length = try decodeAndCheckDDSSequenceLength(decoder: &decoder)

        reserveLengthDDSDecode(length: length)

        reserveCapacity(Int(length))
        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}

extension Array where Element == Int64 {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        addPrimitiveHeaderSize(calculator: &calculator)

        let calculatedSize = (count &* 8) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: calculator.align64)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize

        setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE_8)
    }

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(UInt32(count)) else {
            throw .notEnoughStorage
        }
        let success = withUnsafeBufferPointer { bufferPtr in
            encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
        }
        guard success else {
            throw .notEnoughStorage
        }
        setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE_8)
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        let length = try decodeAndCheckDDSSequenceLength(decoder: &decoder)

        reserveLengthDDSDecode(length: length)

        reserveCapacity(Int(length))
        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}
extension Array where Element == UInt64 {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        addPrimitiveHeaderSize(calculator: &calculator)

        let calculatedSize = (count &* 8) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: calculator.align64)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize

        setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE_8)
    }

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(UInt32(count)) else {
            throw .notEnoughStorage
        }
        let success = withUnsafeBufferPointer { bufferPtr in
            encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
        }
        guard success else {
            throw .notEnoughStorage
        }
        setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE_8)
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        let length = try decodeAndCheckDDSSequenceLength(decoder: &decoder)

        reserveLengthDDSDecode(length: length)

        reserveCapacity(Int(length))
        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}
extension Array where Element == Float {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        addPrimitiveHeaderSize(calculator: &calculator)

        let calculatedSize = (count &* 4) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize

        setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE_4)
    }

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(UInt32(count)) else {
            throw .notEnoughStorage
        }
        let success = withUnsafeBufferPointer { bufferPtr in
            encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
        }
        guard success else {
            throw .notEnoughStorage
        }
        setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE_4)
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        let length = try decodeAndCheckDDSSequenceLength(decoder: &decoder)

        reserveLengthDDSDecode(length: length)

        reserveCapacity(Int(length))
        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}
extension Array where Element == Double {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        addPrimitiveHeaderSize(calculator: &calculator)

        let calculatedSize = (count &* 8) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: calculator.align64)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize

        setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE_8)
    }

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(UInt32(count)) else {
            throw .notEnoughStorage
        }
        let success = withUnsafeBufferPointer { bufferPtr in
            encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
        }
        guard success else {
            throw .notEnoughStorage
        }
        setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE_8)
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        let length = try decodeAndCheckDDSSequenceLength(decoder: &decoder)

        reserveLengthDDSDecode(length: length)

        reserveCapacity(Int(length))
        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}
#if !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS)))) && (arch(i386) || arch(x86_64))
extension Array where Element == Float80 {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        addPrimitiveHeaderSize(calculator: &calculator)

        let calculatedSize = (count &* 16) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: calculator.align64)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize

        setSerializedMemberSize(calculator: &calculator, size: .NO_SERIALIZED_MEMBER_SIZE)
    }

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(UInt32(count)) else {
            throw .notEnoughStorage
        }
        let success = withUnsafeBufferPointer { bufferPtr in
            encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
        }
        guard success else {
            throw .notEnoughStorage
        }
        setSerializedMemberSize(encoder: &encoder, size: .NO_SERIALIZED_MEMBER_SIZE)
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        let length = try decodeAndCheckDDSSequenceLength(decoder: &decoder)

        reserveLengthDDSDecode(length: length)

        reserveCapacity(Int(length))
        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}
#endif
