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
    calculator: inout DDSSizeCalculator,
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
        calculator.serializedSequenceMemberSize = .SERIALIZED_MEMBER_SIZE
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
    encoder: inout DDSEncoder, length: Int32,
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
internal func decodeAndCheckDDSSequenceLength(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) -> Int32 {
    var length: Int32 = 0
    guard decoder.deserializer.deserialize(&length) else {
        throw .outOfBounds
    }
    guard decoder.deserializer.sizeRemaining >= length else {
        throw .outOfBounds
    }
    return length
}

extension Array: DDSCodable where Element: DDSCodable {
    @_alwaysEmitIntoClient
    public static var ddsInitialized: [Element] { .init() }

    @_alwaysEmitIntoClient
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        if Element.self == Bool.self {
            return .createUnboundedArray(of: Bool.ddsTypeDescriptor, primitive: true)
        } else if Element.self == Int.self {
            return .createUnboundedArray(of: Int.ddsTypeDescriptor, primitive: true)
        } else if Element.self == UInt.self {
            return .createUnboundedArray(of: UInt.ddsTypeDescriptor, primitive: true)
        } else if Element.self == Int8.self {
            return .createUnboundedArray(of: Int8.ddsTypeDescriptor, primitive: true)
        } else if Element.self == UInt8.self {
            return .createUnboundedArray(of: UInt8.ddsTypeDescriptor, primitive: true)
        } else if Element.self == Int16.self {
            return .createUnboundedArray(of: Int16.ddsTypeDescriptor, primitive: true)
        } else if Element.self == UInt16.self {
            return .createUnboundedArray(of: UInt16.ddsTypeDescriptor, primitive: true)
        } else if Element.self == Int32.self {
            return .createUnboundedArray(of: Int32.ddsTypeDescriptor, primitive: true)
        } else if Element.self == UInt32.self {
            return .createUnboundedArray(of: UInt32.ddsTypeDescriptor, primitive: true)
        } else if Element.self == Int64.self {
            return .createUnboundedArray(of: Int64.ddsTypeDescriptor, primitive: true)
        } else if Element.self == UInt64.self {
            return .createUnboundedArray(of: UInt64.ddsTypeDescriptor, primitive: true)
        } else if Element.self == Float.self {
            return .createUnboundedArray(of: Float.ddsTypeDescriptor, primitive: true)
        } else if Element.self == Double.self {
            return .createUnboundedArray(of: Double.ddsTypeDescriptor, primitive: true)
        }
        #if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
            if Element.self == Float16.self {
                return .createUnboundedArray(of: Float16.ddsTypeDescriptor, primitive: true)
            }
        #endif
        #if !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS)))) && (arch(i386) || arch(x86_64))
            if Element.self == Float80.self {
                return .createUnboundedArray(of: Float80.ddsTypeDescriptor, primitive: true)
            }
        #endif

        return .createUnboundedArray(of: Element.ddsTypeDescriptor, primitive: false)
    }

    @_alwaysEmitIntoClient
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        if Element.self == Bool.self {
            calculateDDSSizeSpecialized(calculator: &calculator, count: count, for: Bool.self)
            return
        } else if Element.self == Int.self {
            calculateDDSSizeSpecialized(calculator: &calculator, count: count, for: Int.self)
            return
        } else if Element.self == UInt.self {
            calculateDDSSizeSpecialized(calculator: &calculator, count: count, for: UInt.self)
            return
        } else if Element.self == Int8.self {
            calculateDDSSizeSpecialized(calculator: &calculator, count: count, for: Int8.self)
            return
        } else if Element.self == UInt8.self {
            calculateDDSSizeSpecialized(calculator: &calculator, count: count, for: UInt8.self)
            return
        } else if Element.self == Int16.self {
            calculateDDSSizeSpecialized(calculator: &calculator, count: count, for: Int16.self)
            return
        } else if Element.self == UInt16.self {
            calculateDDSSizeSpecialized(calculator: &calculator, count: count, for: UInt16.self)
            return
        } else if Element.self == Int32.self {
            calculateDDSSizeSpecialized(calculator: &calculator, count: count, for: Int32.self)
            return
        } else if Element.self == UInt32.self {
            calculateDDSSizeSpecialized(calculator: &calculator, count: count, for: UInt32.self)
            return
        } else if Element.self == Int64.self {
            calculateDDSSizeSpecialized(calculator: &calculator, count: count, for: Int64.self)
            return
        } else if Element.self == UInt64.self {
            calculateDDSSizeSpecialized(calculator: &calculator, count: count, for: UInt64.self)
            return
        } else if Element.self == Float.self {
            calculateDDSSizeSpecialized(calculator: &calculator, count: count, for: Float.self)
            return
        } else if Element.self == Double.self {
            calculateDDSSizeSpecialized(calculator: &calculator, count: count, for: Double.self)
            return
        }
        #if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
            if Element.self == Float16.self {
                calculateDDSSizeSpecialized(calculator: &calculator, count: count, for: Float16.self)
                return
            }
        #endif
        #if !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS)))) && (arch(i386) || arch(x86_64))
            if Element.self == Float80.self {
                calculateDDSSizeSpecialized(calculator: &calculator, count: count, for: Float80.self)
                return
            }
        #endif

        withDDSSizeCalculatorComplexSequence(calculator: &calculator) { calculator in
            for element in self {
                element.calculateDDSSize(calculator: &calculator)
            }
        }
    }

    @_alwaysEmitIntoClient
    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        var error: DDSEncoder.EncodingError? = nil
        if Element.self == Bool.self {
            withUnsafeBufferPointer { bufferPtr in
                bufferPtr.withMemoryRebound(to: Bool.self) { bufferPtr in
                    do throws(DDSEncoder.EncodingError) {
                        try ddsEncodeSpecialized(encoder: &encoder, count: count, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
            }
            if let error { throw error } else { return }
        } else if Element.self == Int.self {
            withUnsafeBufferPointer { bufferPtr in
                bufferPtr.withMemoryRebound(to: Int.self) { bufferPtr in
                    do throws(DDSEncoder.EncodingError) {
                        try ddsEncodeSpecialized(encoder: &encoder, count: count, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
            }
            if let error { throw error } else { return }
        } else if Element.self == UInt.self {
            withUnsafeBufferPointer { bufferPtr in
                bufferPtr.withMemoryRebound(to: UInt.self) { bufferPtr in
                    do throws(DDSEncoder.EncodingError) {
                        try ddsEncodeSpecialized(encoder: &encoder, count: count, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
            }
            if let error { throw error } else { return }
        } else if Element.self == Int8.self {
            withUnsafeBufferPointer { bufferPtr in
                bufferPtr.withMemoryRebound(to: Int8.self) { bufferPtr in
                    do throws(DDSEncoder.EncodingError) {
                        try ddsEncodeSpecialized(encoder: &encoder, count: count, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
            }
            if let error { throw error } else { return }
        } else if Element.self == UInt8.self {
            withUnsafeBufferPointer { bufferPtr in
                bufferPtr.withMemoryRebound(to: UInt8.self) { bufferPtr in
                    do throws(DDSEncoder.EncodingError) {
                        try ddsEncodeSpecialized(encoder: &encoder, count: count, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
            }
            if let error { throw error } else { return }
        } else if Element.self == Int16.self {
            withUnsafeBufferPointer { bufferPtr in
                bufferPtr.withMemoryRebound(to: Int16.self) { bufferPtr in
                    do throws(DDSEncoder.EncodingError) {
                        try ddsEncodeSpecialized(encoder: &encoder, count: count, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
            }
            if let error { throw error } else { return }
        } else if Element.self == UInt16.self {
            withUnsafeBufferPointer { bufferPtr in
                bufferPtr.withMemoryRebound(to: UInt16.self) { bufferPtr in
                    do throws(DDSEncoder.EncodingError) {
                        try ddsEncodeSpecialized(encoder: &encoder, count: count, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
            }
            if let error { throw error } else { return }
        } else if Element.self == Int32.self {
            withUnsafeBufferPointer { bufferPtr in
                bufferPtr.withMemoryRebound(to: Int32.self) { bufferPtr in
                    do throws(DDSEncoder.EncodingError) {
                        try ddsEncodeSpecialized(encoder: &encoder, count: count, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
            }
            if let error { throw error } else { return }
        } else if Element.self == UInt32.self {
            withUnsafeBufferPointer { bufferPtr in
                bufferPtr.withMemoryRebound(to: UInt32.self) { bufferPtr in
                    do throws(DDSEncoder.EncodingError) {
                        try ddsEncodeSpecialized(encoder: &encoder, count: count, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
            }
            if let error { throw error } else { return }
        } else if Element.self == Int64.self {
            withUnsafeBufferPointer { bufferPtr in
                bufferPtr.withMemoryRebound(to: Int64.self) { bufferPtr in
                    do throws(DDSEncoder.EncodingError) {
                        try ddsEncodeSpecialized(encoder: &encoder, count: count, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
            }
            if let error { throw error } else { return }
        } else if Element.self == UInt64.self {
            withUnsafeBufferPointer { bufferPtr in
                bufferPtr.withMemoryRebound(to: UInt64.self) { bufferPtr in
                    do throws(DDSEncoder.EncodingError) {
                        try ddsEncodeSpecialized(encoder: &encoder, count: count, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
            }
            if let error { throw error } else { return }
        } else if Element.self == Float.self {
            withUnsafeBufferPointer { bufferPtr in
                bufferPtr.withMemoryRebound(to: Float.self) { bufferPtr in
                    do throws(DDSEncoder.EncodingError) {
                        try ddsEncodeSpecialized(encoder: &encoder, count: count, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
            }
            if let error { throw error } else { return }
        } else if Element.self == Double.self {
            withUnsafeBufferPointer { bufferPtr in
                bufferPtr.withMemoryRebound(to: Double.self) { bufferPtr in
                    do throws(DDSEncoder.EncodingError) {
                        try ddsEncodeSpecialized(encoder: &encoder, count: count, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
            }
            if let error { throw error } else { return }
        }
        #if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
            if Element.self == Float16.self {
                withUnsafeBufferPointer { bufferPtr in
                    bufferPtr.withMemoryRebound(to: Float16.self) { bufferPtr in
                        do throws(DDSEncoder.EncodingError) {
                            try ddsEncodeSpecialized(encoder: &encoder, count: count, bufferPtr: bufferPtr)
                        } catch let e { error = e }
                    }
                }
                if let error { throw error } else { return }
            }
        #endif
        #if !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS)))) && (arch(i386) || arch(x86_64))
            if Element.self == Float80.self {
                withUnsafeBufferPointer { bufferPtr in
                    bufferPtr.withMemoryRebound(to: Float80.self) { bufferPtr in
                        do throws(DDSEncoder.EncodingError) {
                            try ddsEncodeSpecialized(encoder: &encoder, count: count, bufferPtr: bufferPtr)
                        } catch let e { error = e }
                    }
                }
                if let error { throw error } else { return }
            }
        #endif

        try withDDSEncoderComplexSequence(encoder: &encoder, length: Int32(count)) { encoder throws(DDSEncoder.EncodingError) in
            for element in self {
                try element.ddsEncode(encoder: &encoder)
            }
        }
    }

    /// Reserve space for the length of the sequence in the array before decoding into it.
    /// This is used internally.
    /// - Parameter length: The length of the sequence.
    @inlinable
    internal mutating func reserveLengthDDSDecode(length: Int32) {
        if length == 0 {
            removeAll(keepingCapacity: true)
        } else if length > capacity {
            // Reallocate the entire array because it is most likely a just as fast as reserving more space.
            self = .init(repeating: .ddsInitialized, count: Int(length))
        } else {
            removeLast(capacity - Int(length))
        }
    }
    @_alwaysEmitIntoClient
    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        let length = try decodeAndCheckDDSSequenceLength(decoder: &decoder)

        reserveLengthDDSDecode(length: length)

        var error: DDSDecoder.DecodingError? = nil
        if Element.self == Bool.self {
            withUnsafeMutableBufferPointer { bufferPtr in
                bufferPtr.withMemoryRebound(to: Bool.self) { bufferPtr in
                    do throws(DDSDecoder.DecodingError) {
                        try ddsDecodeSpecialized(decoder: &decoder, length: length, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
            }
            if let error { throw error } else { return }
        }

        withUnsafeMutableBufferPointer { bufferPtr in
            if Element.self == Bool.self {
                bufferPtr.withMemoryRebound(to: Bool.self) { bufferPtr in
                    do throws(DDSDecoder.DecodingError) {
                        try ddsDecodeSpecialized(decoder: &decoder, length: length, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
                return
            } else if Element.self == Int.self {
                bufferPtr.withMemoryRebound(to: Int.self) { bufferPtr in
                    do throws(DDSDecoder.DecodingError) {
                        try ddsDecodeSpecialized(decoder: &decoder, length: length, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
                return
            } else if Element.self == UInt.self {
                bufferPtr.withMemoryRebound(to: UInt.self) { bufferPtr in
                    do throws(DDSDecoder.DecodingError) {
                        try ddsDecodeSpecialized(decoder: &decoder, length: length, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
                return
            } else if Element.self == Int8.self {
                bufferPtr.withMemoryRebound(to: Int8.self) { bufferPtr in
                    do throws(DDSDecoder.DecodingError) {
                        try ddsDecodeSpecialized(decoder: &decoder, length: length, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
                return
            } else if Element.self == UInt8.self {
                bufferPtr.withMemoryRebound(to: UInt8.self) { bufferPtr in
                    do throws(DDSDecoder.DecodingError) {
                        try ddsDecodeSpecialized(decoder: &decoder, length: length, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
                return
            } else if Element.self == Int16.self {
                bufferPtr.withMemoryRebound(to: Int16.self) { bufferPtr in
                    do throws(DDSDecoder.DecodingError) {
                        try ddsDecodeSpecialized(decoder: &decoder, length: length, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
                return
            } else if Element.self == UInt16.self {
                bufferPtr.withMemoryRebound(to: UInt16.self) { bufferPtr in
                    do throws(DDSDecoder.DecodingError) {
                        try ddsDecodeSpecialized(decoder: &decoder, length: length, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
                return
            } else if Element.self == Int32.self {
                bufferPtr.withMemoryRebound(to: Int32.self) { bufferPtr in
                    do throws(DDSDecoder.DecodingError) {
                        try ddsDecodeSpecialized(decoder: &decoder, length: length, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
                return
            } else if Element.self == UInt32.self {
                bufferPtr.withMemoryRebound(to: UInt32.self) { bufferPtr in
                    do throws(DDSDecoder.DecodingError) {
                        try ddsDecodeSpecialized(decoder: &decoder, length: length, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
                return
            } else if Element.self == Int64.self {
                bufferPtr.withMemoryRebound(to: Int64.self) { bufferPtr in
                    do throws(DDSDecoder.DecodingError) {
                        try ddsDecodeSpecialized(decoder: &decoder, length: length, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
                return
            } else if Element.self == UInt64.self {
                bufferPtr.withMemoryRebound(to: UInt64.self) { bufferPtr in
                    do throws(DDSDecoder.DecodingError) {
                        try ddsDecodeSpecialized(decoder: &decoder, length: length, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
                return
            } else if Element.self == Float.self {
                bufferPtr.withMemoryRebound(to: Float.self) { bufferPtr in
                    do throws(DDSDecoder.DecodingError) {
                        try ddsDecodeSpecialized(decoder: &decoder, length: length, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
                return
            } else if Element.self == Double.self {
                bufferPtr.withMemoryRebound(to: Double.self) { bufferPtr in
                    do throws(DDSDecoder.DecodingError) {
                        try ddsDecodeSpecialized(decoder: &decoder, length: length, bufferPtr: bufferPtr)
                    } catch let e { error = e }
                }
                return
            }
            #if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
                if Element.self == Float16.self {
                    bufferPtr.withMemoryRebound(to: Float16.self) { bufferPtr in
                        do throws(DDSDecoder.DecodingError) {
                            try ddsDecodeSpecialized(decoder: &decoder, length: length, bufferPtr: bufferPtr)
                        } catch let e { error = e }
                    }
                    return
                }
            #endif
            #if !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS)))) && (arch(i386) || arch(x86_64))
                if Element.self == Float80.self {
                    bufferPtr.withMemoryRebound(to: Float80.self) { bufferPtr in
                        do throws(DDSDecoder.DecodingError) {
                            try ddsDecodeSpecialized(decoder: &decoder, length: length, bufferPtr: bufferPtr)
                        } catch let e { error = e }
                    }
                    return
                }
            #endif

            let ptr = bufferPtr.baseAddress.unsafelyUnwrapped  // This should always be defined because we reserved capacity above.
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

/// Bool

@usableFromInline
internal func calculateDDSSizeSpecialized(calculator: inout DDSSizeCalculator, count: Int, for: Bool.Type) {
    let calculatedSize = count &+ 4 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
    calculator.alignment += calculatedSize
    calculator.size += calculatedSize
}
@usableFromInline
internal func ddsEncodeSpecialized(
    encoder: inout DDSEncoder,
    count: Int, bufferPtr: UnsafeBufferPointer<Bool>
) throws(DDSEncoder.EncodingError) {
    guard encoder.serializer.serialize(Int32(count)) else {
        throw .notEnoughStorage
    }
    let success = encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
    guard success else {
        throw .notEnoughStorage
    }
}
@usableFromInline
internal func ddsDecodeSpecialized(
    decoder: inout DDSDecoder,
    length: Int32, bufferPtr: UnsafeMutableBufferPointer<Bool>
) throws(DDSDecoder.DecodingError) {
    let success = decoder.deserializer.deserializeArray(bufferPtr.baseAddress, UInt32(length))
    guard success else {
        throw .outOfBounds
    }
}

/// Int

@usableFromInline
internal func calculateDDSSizeSpecialized(calculator: inout DDSSizeCalculator, count: Int, for: Int.Type) {
    addPrimitiveHeaderSize(calculator: &calculator)

    let calculatedSize =
        if MemoryLayout<Int>.size == 8 {
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
@usableFromInline
internal func ddsEncodeSpecialized(
    encoder: inout DDSEncoder,
    count: Int, bufferPtr: UnsafeBufferPointer<Int>
) throws(DDSEncoder.EncodingError) {
    guard encoder.serializer.serialize(Int32(count)) else {
        throw .notEnoughStorage
    }
    let success =
        if MemoryLayout<Int>.size == 8 {
            bufferPtr.withMemoryRebound(to: Int64.self) { bufferPtr in
                encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
            }
        } else {
            bufferPtr.withMemoryRebound(to: Int32.self) { bufferPtr in
                encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
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
@usableFromInline
internal func ddsDecodeSpecialized(
    decoder: inout DDSDecoder,
    length: Int32, bufferPtr: UnsafeMutableBufferPointer<Int>
) throws(DDSDecoder.DecodingError) {
    let success =
        if MemoryLayout<Int>.size == 8 {
            bufferPtr.withMemoryRebound(to: Int64.self) { bufferPtr in
                decoder.deserializer.deserializeArray(bufferPtr.baseAddress, UInt32(length))
            }
        } else {
            bufferPtr.withMemoryRebound(to: Int32.self) { bufferPtr in
                decoder.deserializer.deserializeArray(bufferPtr.baseAddress, UInt32(length))
            }
        }
    guard success else {
        throw .outOfBounds
    }
}

/// UInt

@usableFromInline
internal func calculateDDSSizeSpecialized(calculator: inout DDSSizeCalculator, count: Int, for: UInt.Type) {
    addPrimitiveHeaderSize(calculator: &calculator)

    let calculatedSize =
        if MemoryLayout<UInt>.size == 8 {
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
@usableFromInline
internal func ddsEncodeSpecialized(
    encoder: inout DDSEncoder,
    count: Int, bufferPtr: UnsafeBufferPointer<UInt>
) throws(DDSEncoder.EncodingError) {
    guard encoder.serializer.serialize(Int32(count)) else {
        throw .notEnoughStorage
    }
    let success =
        if MemoryLayout<UInt>.size == 8 {
            bufferPtr.withMemoryRebound(to: UInt64.self) { bufferPtr in
                encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
            }
        } else {
            bufferPtr.withMemoryRebound(to: UInt32.self) { bufferPtr in
                encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
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
@usableFromInline
internal func ddsDecodeSpecialized(
    decoder: inout DDSDecoder,
    length: Int32, bufferPtr: UnsafeMutableBufferPointer<UInt>
) throws(DDSDecoder.DecodingError) {
    let success =
        if MemoryLayout<Int>.size == 8 {
            bufferPtr.withMemoryRebound(to: UInt64.self) { bufferPtr in
                decoder.deserializer.deserializeArray(bufferPtr.baseAddress, UInt32(length))
            }
        } else {
            bufferPtr.withMemoryRebound(to: UInt32.self) { bufferPtr in
                decoder.deserializer.deserializeArray(bufferPtr.baseAddress, UInt32(length))
            }
        }
    guard success else {
        throw .outOfBounds
    }
}

/// Int8

@usableFromInline
internal func calculateDDSSizeSpecialized(calculator: inout DDSSizeCalculator, count: Int, for: Int8.Type) {
    addPrimitiveHeaderSize(calculator: &calculator)

    calculator.alignment += count
    calculator.size += count

    setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE)
}
@usableFromInline
internal func ddsEncodeSpecialized(
    encoder: inout DDSEncoder,
    count: Int, bufferPtr: UnsafeBufferPointer<Int8>
) throws(DDSEncoder.EncodingError) {
    guard encoder.serializer.serialize(Int32(count)) else {
        throw .notEnoughStorage
    }
    let success = encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
    guard success else {
        throw .notEnoughStorage
    }
    setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE)
}
@usableFromInline
internal func ddsDecodeSpecialized(
    decoder: inout DDSDecoder,
    length: Int32, bufferPtr: UnsafeMutableBufferPointer<Int8>
) throws(DDSDecoder.DecodingError) {
    let success = decoder.deserializer.deserializeArray(bufferPtr.baseAddress, UInt32(length))
    guard success else {
        throw .outOfBounds
    }
}

/// UInt8

@usableFromInline
internal func calculateDDSSizeSpecialized(calculator: inout DDSSizeCalculator, count: Int, for: UInt8.Type) {
    addPrimitiveHeaderSize(calculator: &calculator)

    calculator.alignment += count
    calculator.size += count

    setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE)
}
@usableFromInline
internal func ddsEncodeSpecialized(
    encoder: inout DDSEncoder,
    count: Int, bufferPtr: UnsafeBufferPointer<UInt8>
) throws(DDSEncoder.EncodingError) {
    guard encoder.serializer.serialize(Int32(count)) else {
        throw .notEnoughStorage
    }
    let success = encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
    guard success else {
        throw .notEnoughStorage
    }
    setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE)
}
@usableFromInline
internal func ddsDecodeSpecialized(
    decoder: inout DDSDecoder,
    length: Int32, bufferPtr: UnsafeMutableBufferPointer<UInt8>
) throws(DDSDecoder.DecodingError) {
    let success = decoder.deserializer.deserializeArray(bufferPtr.baseAddress, UInt32(length))
    guard success else {
        throw .outOfBounds
    }
}

/// Int16

@usableFromInline
internal func calculateDDSSizeSpecialized(calculator: inout DDSSizeCalculator, count: Int, for: Int16.Type) {
    addPrimitiveHeaderSize(calculator: &calculator)

    let calculatedSize = (count &* 2) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 2)
    calculator.alignment += calculatedSize
    calculator.size += calculatedSize

    setSerializedMemberSize(calculator: &calculator, size: .NO_SERIALIZED_MEMBER_SIZE)
}
@usableFromInline
internal func ddsEncodeSpecialized(
    encoder: inout DDSEncoder,
    count: Int, bufferPtr: UnsafeBufferPointer<Int16>
) throws(DDSEncoder.EncodingError) {
    guard encoder.serializer.serialize(Int32(count)) else {
        throw .notEnoughStorage
    }
    let success = encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
    guard success else {
        throw .notEnoughStorage
    }
    setSerializedMemberSize(encoder: &encoder, size: .NO_SERIALIZED_MEMBER_SIZE)
}
@usableFromInline
internal func ddsDecodeSpecialized(
    decoder: inout DDSDecoder,
    length: Int32, bufferPtr: UnsafeMutableBufferPointer<Int16>
) throws(DDSDecoder.DecodingError) {
    let success = decoder.deserializer.deserializeArray(bufferPtr.baseAddress, UInt32(length))
    guard success else {
        throw .outOfBounds
    }
}

/// UInt16

@usableFromInline
internal func calculateDDSSizeSpecialized(calculator: inout DDSSizeCalculator, count: Int, for: UInt16.Type) {
    addPrimitiveHeaderSize(calculator: &calculator)

    let calculatedSize = (count &* 2) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 2)
    calculator.alignment += calculatedSize
    calculator.size += calculatedSize

    setSerializedMemberSize(calculator: &calculator, size: .NO_SERIALIZED_MEMBER_SIZE)
}
@usableFromInline
internal func ddsEncodeSpecialized(
    encoder: inout DDSEncoder,
    count: Int, bufferPtr: UnsafeBufferPointer<UInt16>
) throws(DDSEncoder.EncodingError) {
    guard encoder.serializer.serialize(Int32(count)) else {
        throw .notEnoughStorage
    }
    let success = encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
    guard success else {
        throw .notEnoughStorage
    }
    setSerializedMemberSize(encoder: &encoder, size: .NO_SERIALIZED_MEMBER_SIZE)
}
@usableFromInline
internal func ddsDecodeSpecialized(
    decoder: inout DDSDecoder,
    length: Int32, bufferPtr: UnsafeMutableBufferPointer<UInt16>
) throws(DDSDecoder.DecodingError) {
    let success = decoder.deserializer.deserializeArray(bufferPtr.baseAddress, UInt32(length))
    guard success else {
        throw .outOfBounds
    }
}

/// UInt16

@usableFromInline
internal func calculateDDSSizeSpecialized(calculator: inout DDSSizeCalculator, count: Int, for: Int32.Type) {
    addPrimitiveHeaderSize(calculator: &calculator)

    let calculatedSize = (count &* 4) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
    calculator.alignment += calculatedSize
    calculator.size += calculatedSize

    setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE_4)
}
@usableFromInline
internal func ddsEncodeSpecialized(
    encoder: inout DDSEncoder,
    count: Int, bufferPtr: UnsafeBufferPointer<Int32>
) throws(DDSEncoder.EncodingError) {
    guard encoder.serializer.serialize(Int32(count)) else {
        throw .notEnoughStorage
    }
    let success = encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
    guard success else {
        throw .notEnoughStorage
    }
    setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE_4)
}
@usableFromInline
internal func ddsDecodeSpecialized(
    decoder: inout DDSDecoder,
    length: Int32, bufferPtr: UnsafeMutableBufferPointer<Int32>
) throws(DDSDecoder.DecodingError) {
    let success = decoder.deserializer.deserializeArray(bufferPtr.baseAddress, UInt32(length))
    guard success else {
        throw .outOfBounds
    }
}

/// UInt32

@usableFromInline
internal func calculateDDSSizeSpecialized(calculator: inout DDSSizeCalculator, count: Int, for: UInt32.Type) {
    addPrimitiveHeaderSize(calculator: &calculator)

    let calculatedSize = (count &* 4) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
    calculator.alignment += calculatedSize
    calculator.size += calculatedSize

    setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE_4)
}
@usableFromInline
internal func ddsEncodeSpecialized(
    encoder: inout DDSEncoder,
    count: Int, bufferPtr: UnsafeBufferPointer<UInt32>
) throws(DDSEncoder.EncodingError) {
    guard encoder.serializer.serialize(Int32(count)) else {
        throw .notEnoughStorage
    }
    let success = encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
    guard success else {
        throw .notEnoughStorage
    }
    setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE_4)
}
@usableFromInline
internal func ddsDecodeSpecialized(
    decoder: inout DDSDecoder,
    length: Int32, bufferPtr: UnsafeMutableBufferPointer<UInt32>
) throws(DDSDecoder.DecodingError) {
    let success = decoder.deserializer.deserializeArray(bufferPtr.baseAddress, UInt32(length))
    guard success else {
        throw .outOfBounds
    }
}

/// Int64

@usableFromInline
internal func calculateDDSSizeSpecialized(calculator: inout DDSSizeCalculator, count: Int, for: Int64.Type) {
    addPrimitiveHeaderSize(calculator: &calculator)

    let calculatedSize =
        (count &* 8) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: DDSSizeCalculator.align64)
    calculator.alignment += calculatedSize
    calculator.size += calculatedSize

    setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE_8)
}
@usableFromInline
internal func ddsEncodeSpecialized(
    encoder: inout DDSEncoder,
    count: Int, bufferPtr: UnsafeBufferPointer<Int64>
) throws(DDSEncoder.EncodingError) {
    guard encoder.serializer.serialize(Int32(count)) else {
        throw .notEnoughStorage
    }
    let success = encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
    guard success else {
        throw .notEnoughStorage
    }
    setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE_8)
}
@usableFromInline
internal func ddsDecodeSpecialized(
    decoder: inout DDSDecoder,
    length: Int32, bufferPtr: UnsafeMutableBufferPointer<Int64>
) throws(DDSDecoder.DecodingError) {
    let success = decoder.deserializer.deserializeArray(bufferPtr.baseAddress, UInt32(length))
    guard success else {
        throw .outOfBounds
    }
}

/// UInt64

@usableFromInline
internal func calculateDDSSizeSpecialized(calculator: inout DDSSizeCalculator, count: Int, for: UInt64.Type) {
    addPrimitiveHeaderSize(calculator: &calculator)

    let calculatedSize =
        (count &* 8) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: DDSSizeCalculator.align64)
    calculator.alignment += calculatedSize
    calculator.size += calculatedSize

    setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE_8)
}
@usableFromInline
internal func ddsEncodeSpecialized(
    encoder: inout DDSEncoder,
    count: Int, bufferPtr: UnsafeBufferPointer<UInt64>
) throws(DDSEncoder.EncodingError) {
    guard encoder.serializer.serialize(Int32(count)) else {
        throw .notEnoughStorage
    }
    let success = encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
    guard success else {
        throw .notEnoughStorage
    }
    setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE_8)
}
@usableFromInline
internal func ddsDecodeSpecialized(
    decoder: inout DDSDecoder,
    length: Int32, bufferPtr: UnsafeMutableBufferPointer<UInt64>
) throws(DDSDecoder.DecodingError) {
    let success = decoder.deserializer.deserializeArray(bufferPtr.baseAddress, UInt32(length))
    guard success else {
        throw .outOfBounds
    }
}

/// Float16

#if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
    @usableFromInline
    internal func calculateDDSSizeSpecialized(calculator: inout DDSSizeCalculator, count: Int, for: Float16.Type) {
        addPrimitiveHeaderSize(calculator: &calculator)

        let calculatedSize = (count &* 2) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 2)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize

        setSerializedMemberSize(calculator: &calculator, size: .NO_SERIALIZED_MEMBER_SIZE)
    }
    @usableFromInline
    internal func ddsEncodeSpecialized(
        encoder: inout DDSEncoder,
        count: Int, bufferPtr: UnsafeBufferPointer<Float16>
    ) throws(DDSEncoder.EncodingError) {
        assert(
            MemoryLayout<Float16>.stride == MemoryLayout<UInt16>.stride,
            "DDSKit: Can't use Float16 because it's memory layout is not the same as UInt16."
        )
        guard encoder.serializer.serialize(Int32(count)) else {
            throw .notEnoughStorage
        }
        let success = bufferPtr.withMemoryRebound(to: UInt16.self) { bufferPtr in
            encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
        }
        guard success else {
            throw .notEnoughStorage
        }
        setSerializedMemberSize(encoder: &encoder, size: .NO_SERIALIZED_MEMBER_SIZE)
    }
    @usableFromInline
    internal func ddsDecodeSpecialized(
        decoder: inout DDSDecoder,
        length: Int32, bufferPtr: UnsafeMutableBufferPointer<Float16>
    ) throws(DDSDecoder.DecodingError) {
        assert(
            MemoryLayout<Float16>.stride == MemoryLayout<UInt16>.stride,
            "DDSKit: Can't use Float16 because it's memory layout is not the same as UInt16."
        )
        let success = bufferPtr.withMemoryRebound(to: UInt16.self) { bufferPtr in
            decoder.deserializer.deserializeArray(bufferPtr.baseAddress, UInt32(length))
        }
        guard success else {
            throw .outOfBounds
        }
    }
#endif

/// Float

@usableFromInline
internal func calculateDDSSizeSpecialized(calculator: inout DDSSizeCalculator, count: Int, for: Float.Type) {
    addPrimitiveHeaderSize(calculator: &calculator)

    let calculatedSize = (count &* 4) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
    calculator.alignment += calculatedSize
    calculator.size += calculatedSize

    setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE_4)
}
@usableFromInline
internal func ddsEncodeSpecialized(
    encoder: inout DDSEncoder,
    count: Int, bufferPtr: UnsafeBufferPointer<Float>
) throws(DDSEncoder.EncodingError) {
    guard encoder.serializer.serialize(Int32(count)) else {
        throw .notEnoughStorage
    }
    let success = encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
    guard success else {
        throw .notEnoughStorage
    }
    setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE_4)
}
@usableFromInline
internal func ddsDecodeSpecialized(
    decoder: inout DDSDecoder,
    length: Int32, bufferPtr: UnsafeMutableBufferPointer<Float>
) throws(DDSDecoder.DecodingError) {
    let success = decoder.deserializer.deserializeArray(bufferPtr.baseAddress, UInt32(length))
    guard success else {
        throw .outOfBounds
    }
}

/// Double

@usableFromInline
internal func calculateDDSSizeSpecialized(calculator: inout DDSSizeCalculator, count: Int, for: Double.Type) {
    addPrimitiveHeaderSize(calculator: &calculator)

    let calculatedSize =
        (count &* 8) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: DDSSizeCalculator.align64)
    calculator.alignment += calculatedSize
    calculator.size += calculatedSize

    setSerializedMemberSize(calculator: &calculator, size: .SERIALIZED_MEMBER_SIZE_8)
}
@usableFromInline
internal func ddsEncodeSpecialized(
    encoder: inout DDSEncoder,
    count: Int, bufferPtr: UnsafeBufferPointer<Double>
) throws(DDSEncoder.EncodingError) {
    guard encoder.serializer.serialize(Int32(count)) else {
        throw .notEnoughStorage
    }
    let success = encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
    guard success else {
        throw .notEnoughStorage
    }
    setSerializedMemberSize(encoder: &encoder, size: .SERIALIZED_MEMBER_SIZE_8)
}
@usableFromInline
internal func ddsDecodeSpecialized(
    decoder: inout DDSDecoder,
    length: Int32, bufferPtr: UnsafeMutableBufferPointer<Double>
) throws(DDSDecoder.DecodingError) {
    let success = decoder.deserializer.deserializeArray(bufferPtr.baseAddress, UInt32(length))
    guard success else {
        throw .outOfBounds
    }
}

/// Float80

#if !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS)))) && (arch(i386) || arch(x86_64))
    @usableFromInline
    internal func calculateDDSSizeSpecialized(calculator: inout DDSSizeCalculator, count: Int, for: Float80.Type) {
        addPrimitiveHeaderSize(calculator: &calculator)

        let calculatedSize =
            (count &* 16) &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: DDSSizeCalculator.align64)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize

        setSerializedMemberSize(calculator: &calculator, size: .NO_SERIALIZED_MEMBER_SIZE)
    }

    @usableFromInline
    internal func ddsEncodeSpecialized(
        encoder: inout DDSEncoder,
        count: Int, bufferPtr: UnsafeBufferPointer<Float80>
    ) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(Int32(count)) else {
            throw .notEnoughStorage
        }
        let success = encoder.serializer.serializeArray(bufferPtr.baseAddress, UInt32(count))
        guard success else {
            throw .notEnoughStorage
        }
        setSerializedMemberSize(encoder: &encoder, size: .NO_SERIALIZED_MEMBER_SIZE)
    }
    @usableFromInline
    internal func ddsDecodeSpecialized(
        decoder: inout DDSDecoder,
        length: Int32, bufferPtr: UnsafeMutableBufferPointer<Float80>
    ) throws(DDSDecoder.DecodingError) {
        let success = decoder.deserializer.deserializeArray(bufferPtr.baseAddress, UInt32(length))
        guard success else {
            throw .outOfBounds
        }
    }
#endif
