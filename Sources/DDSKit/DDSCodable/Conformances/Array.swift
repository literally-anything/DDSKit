/**
 * Array.swift
 * Conformances
 * 
 * Created by Hunter Baker on 3/25/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

/// Calculate the size of a DDS sequence of complex types.
/// This is only used internally.
/// - Parameters:
///   - calculator: The calculator to use.
///   - length: The length of the sequence.
///   - body: The body callback that calculates the size of the elements.
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
/// Encode a DDS sequence of complex types.
/// This is only used internally.
/// - Parameters:
///   - encoder: The encoder to use.
///   - length: The length of the sequence.
///   - body: The body callback that encodes the elements.
/// - Throws: An error if there is not enough storage allocated to encode the data or some other unexpected error occurs in `body`.
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
/// Decode the length of a DDS sequence and check that the decoder has enough space for the entire sequence to be decoded.
/// This is only used internally.
/// - Parameter decoder: The decoder to use.
/// - Throws: An error if the decoder reads beyond the bounds of the internal buffer.
/// - Returns: The read length of the sequence.
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
        .createUnboundedArray(of: Element.ddsTypeDescriptor, primitive: false)
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

// Specific specializations for primitive types.
// There needs to be this much duplication because the specializations in c++ have no connection to any Swift protocols I make.
// This makes Swift complain because not every type that could conform to the protocol can be passed to an overload of the c++ function.

/// Add the size of the sequence header for primitive types to the calculator.
/// This is used internally.
/// - Parameter calculator: The calculator to use.
private func addPrimitiveHeaderSize(calculator: inout DDSSizeCalculator) {
    let initialAlignment = calculator.alignment
    calculator.alignment += 4 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
    calculator.size += calculator.alignment &- initialAlignment
}
/// Set the serialized member size for primitive types on a size calculator.
/// This is used internally.
/// - Parameters:
///   - calculator: The calculator to use.
///   - size: The size to set when necessary.
private func setSerializedMemberSize(calculator: inout DDSSizeCalculator, size: FastDDS.CDR.SerializedMemberSizeForNextInt) {
    if calculator.calc.get_cdr_version() == eprosima.fastcdr.XCDRv2 {
        // Inform DHEADER can be joined with NEXTINT
        calculator.serializedSequenceMemberSize = size
    }
}
/// Set the serialized member size for primitive types on an encoder.
/// This is used internally.
/// - Parameters:
///   - encoder: The encoder to use.
///   - size: The size to set when necessary.
private func setSerializedMemberSize(encoder: inout DDSEncoder, size: FastDDS.CDR.SerializedMemberSizeForNextInt) {
    if encoder.serializer.cdrVersion == eprosima.fastcdr.XCDRv2 {
        encoder.serializer.serializedMemberSize = size
    }
}

extension Array where Element == Bool {
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        .createUnboundedArray(of: Bool.ddsTypeDescriptor, primitive: true)
    }

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

        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}

extension Array where Element == Int {
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        .createUnboundedArray(of: Int.ddsTypeDescriptor, primitive: true)
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        addPrimitiveHeaderSize(calculator: &calculator)

        let calculatedSize = if MemoryLayout<Int>.size == 8 {
            (count &* 8) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: DDSSizeCalculator.align64)
        } else {
            (count &* 4) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
        }
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize

        if MemoryLayout<Int>.size == 8 {
            setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE_8)
        } else {
            setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE_4)
        }
    }

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(UInt32(count)) else {
            throw .notEnoughStorage
        }
        let success = withUnsafeBufferPointer { bufferPtr in
            if MemoryLayout<Int>.size == 8 {
                bufferPtr.withMemoryRebound(to: Int64.self) { bufferPtr in
                    encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
                }
            } else {
                bufferPtr.withMemoryRebound(to: Int32.self) { bufferPtr in
                    encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
                }
            }
        }
        guard success else {
            throw .notEnoughStorage
        }
        if MemoryLayout<Int>.size == 8 {
            setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE_8)
        } else {
            setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE_4)
        }
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        let length = try decodeAndCheckDDSSequenceLength(decoder: &decoder)

        reserveLengthDDSDecode(length: length)

        let success = withUnsafeMutableBufferPointer { bufferPtr in
            if MemoryLayout<Int>.size == 8 {
                bufferPtr.withMemoryRebound(to: Int64.self) { bufferPtr in
                    decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
                }
            } else {
                bufferPtr.withMemoryRebound(to: Int32.self) { bufferPtr in
                    decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
                }
            }
        }
        guard success else {
            throw .outOfBounds
        }
    }
}
extension Array where Element == UInt {
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        .createUnboundedArray(of: UInt.ddsTypeDescriptor, primitive: true)
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        addPrimitiveHeaderSize(calculator: &calculator)

        let calculatedSize = if MemoryLayout<UInt>.size == 8 {
            (count &* 8) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: DDSSizeCalculator.align64)
        } else {
            (count &* 4) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
        }
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize

        if MemoryLayout<UInt>.size == 8 {
            setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE_8)
        } else {
            setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE_4)
        }
    }

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(UInt32(count)) else {
            throw .notEnoughStorage
        }
        let success = withUnsafeBufferPointer { bufferPtr in
            if MemoryLayout<UInt>.size == 8 {
                bufferPtr.withMemoryRebound(to: UInt64.self) { bufferPtr in
                    encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
                }
            } else {
                bufferPtr.withMemoryRebound(to: UInt32.self) { bufferPtr in
                    encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
                }
            }
        }
        guard success else {
            throw .notEnoughStorage
        }
        if MemoryLayout<UInt>.size == 8 {
            setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE_8)
        } else {
            setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE_4)
        }
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        let length = try decodeAndCheckDDSSequenceLength(decoder: &decoder)

        reserveLengthDDSDecode(length: length)

        let success = withUnsafeMutableBufferPointer { bufferPtr in
            if MemoryLayout<Int>.size == 8 {
                bufferPtr.withMemoryRebound(to: UInt64.self) { bufferPtr in
                    decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
                }
            } else {
                bufferPtr.withMemoryRebound(to: UInt32.self) { bufferPtr in
                    decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
                }
            }
        }
        guard success else {
            throw .outOfBounds
        }
    }
}

extension Array where Element == Int8 {
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        .createUnboundedArray(of: Int8.ddsTypeDescriptor, primitive: true)
    }

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

        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}
extension Array where Element == UInt8 {
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        .createUnboundedArray(of: UInt8.ddsTypeDescriptor, primitive: true)
    }

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

        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}

extension Array where Element == Int16 {
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        .createUnboundedArray(of: Int16.ddsTypeDescriptor, primitive: true)
    }

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

        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}
extension Array where Element == UInt16 {
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        .createUnboundedArray(of: UInt16.ddsTypeDescriptor, primitive: true)
    }

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

        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}

extension Array where Element == Int32 {
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        .createUnboundedArray(of: Int32.ddsTypeDescriptor, primitive: true)
    }

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

        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}
extension Array where Element == UInt32 {
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        .createUnboundedArray(of: UInt32.ddsTypeDescriptor, primitive: true)
    }

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

        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}

extension Array where Element == Int64 {
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        .createUnboundedArray(of: Int64.ddsTypeDescriptor, primitive: true)
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        addPrimitiveHeaderSize(calculator: &calculator)

        let calculatedSize = (count &* 8) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: DDSSizeCalculator.align64)
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

        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}
extension Array where Element == UInt64 {
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        .createUnboundedArray(of: UInt64.ddsTypeDescriptor, primitive: true)
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        addPrimitiveHeaderSize(calculator: &calculator)

        let calculatedSize = (count &* 8) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: DDSSizeCalculator.align64)
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

        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}
#if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
extension Array where Element == Float16 {
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        .createUnboundedArray(of: Float16.ddsTypeDescriptor, primitive: true)
    }

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
            bufferPtr.withMemoryRebound(to: UInt16.self) { bufferPtr in
                encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
            }
        }
        guard success else {
            throw .notEnoughStorage
        }
        setSerializedMemberSize(encoder: &encoder, size: .NO_SERIALIZED_MEMBER_SIZE)
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        let length = try decodeAndCheckDDSSequenceLength(decoder: &decoder)

        reserveLengthDDSDecode(length: length)

        let success = withUnsafeMutableBufferPointer { bufferPtr in
            bufferPtr.withMemoryRebound(to: UInt16.self) { bufferPtr in
                decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
            }
        }
        guard success else {
            throw .outOfBounds
        }
    }
}
#endif
extension Array where Element == Float {
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        .createUnboundedArray(of: Float.ddsTypeDescriptor, primitive: true)
    }

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

        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}
extension Array where Element == Double {
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        .createUnboundedArray(of: Double.ddsTypeDescriptor, primitive: true)
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        addPrimitiveHeaderSize(calculator: &calculator)

        let calculatedSize = (count &* 8) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: DDSSizeCalculator.align64)
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
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        .createUnboundedArray(of: Float80.ddsTypeDescriptor, primitive: true)
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        addPrimitiveHeaderSize(calculator: &calculator)

        let calculatedSize = (count &* 16) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: DDSSizeCalculator.align64)
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

        let success = withUnsafeMutableBufferPointer { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, length)
        }
        guard success else {
            throw .outOfBounds
        }
    }
}
#endif
