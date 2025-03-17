/**
 * Primatives.swift
 * DDSCodable
 * 
 * Created by Hunter Baker on 3/09/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */

extension Bool: DDSCodable, DDSLoaningCodable {
    @inlinable
    public static var ddsInitialized: Bool { false }

    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        do throws(DDSTypeDescriptor.LookupError) {
            return try DDSTypeDescriptor(lookup: "_bool")
        } catch {
            fatalError("Failed to lookup type descriptor for Bool: _bool")
        }
    }
    /// This will always throw a fatal error.
    /// - Warning: Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.
    @available(*, deprecated, message: "Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    public static var ddsTypeSupport: DDSTypeSupport {
        fatalError("Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        calculator.alignment += 1
        calculator.size += 1
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(self) else {
            throw .notEnoughStorage
        }
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        guard decoder.deserializer.deserialize(&self) else {
            throw .outOfBounds
        }
    }
}

extension Int: DDSCodable, DDSLoaningCodable {
    @inlinable
    public static var ddsInitialized: Int { .zero }

    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        do throws(DDSTypeDescriptor.LookupError) {
            if MemoryLayout<Int>.size == 8 {
                return try DDSTypeDescriptor(lookup: "_int64_t")
            } else {
                return try DDSTypeDescriptor(lookup: "_int32_t")
            }
        } catch {
            fatalError("Failed to lookup type descriptor for Int: \(MemoryLayout<Int>.size == 8 ? "_int64_t" : "_int32_t")")
        }
    }
    /// This will always throw a fatal error.
    /// - Warning: Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.
    @available(*, deprecated, message: "Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    public static var ddsTypeSupport: DDSTypeSupport {
        fatalError("Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        if MemoryLayout<Int>.size == 8 {
            let calculatedSize = 8 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: calculator.align64)
            calculator.alignment += calculatedSize
            calculator.size += calculatedSize
        } else {
            let calculatedSize = 4 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
            calculator.alignment += calculatedSize
            calculator.size += calculatedSize
        }
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        if MemoryLayout<Int>.size == 8 {
            guard encoder.serializer.serialize(Int64(self)) else {
                throw .notEnoughStorage
            }
        } else {
            guard encoder.serializer.serialize(Int32(self)) else {
                throw .notEnoughStorage
            }
        }
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        if MemoryLayout<Int>.size == 8 {
            var value: Int64 = 0
            guard decoder.deserializer.deserialize(&value) else {
                throw .outOfBounds
            }
            self = Int(value)
        } else {
            var value: Int32 = 0
            guard decoder.deserializer.deserialize(&value) else {
                throw .outOfBounds
            }
            self = Int(value)
        }
    }
}
extension UInt: DDSCodable, DDSLoaningCodable {
    @inlinable
    public static var ddsInitialized: UInt { .zero }

    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        do throws(DDSTypeDescriptor.LookupError) {
            if MemoryLayout<UInt>.size == 8 {
                return try DDSTypeDescriptor(lookup: "_uint64_t")
            } else {
                return try DDSTypeDescriptor(lookup: "_uint32_t")
            }
        } catch {
            fatalError("Failed to lookup type descriptor for UInt: \(MemoryLayout<UInt>.size == 8 ? "_uint64_t" : "_uint32_t")")
        }
    }
    /// This will always throw a fatal error.
    /// - Warning: Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.
    @available(*, deprecated, message: "Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    public static var ddsTypeSupport: DDSTypeSupport {
        fatalError("Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        if MemoryLayout<UInt>.size == 8 {
            let calculatedSize = 8 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: calculator.align64)
            calculator.alignment += calculatedSize
            calculator.size += calculatedSize
        } else {
            let calculatedSize = 4 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
            calculator.alignment += calculatedSize
            calculator.size += calculatedSize
        }
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        if MemoryLayout<UInt>.size == 8 {
            guard encoder.serializer.serialize(UInt64(self)) else {
                throw .notEnoughStorage
            }
        } else {
            guard encoder.serializer.serialize(UInt32(self)) else {
                throw .notEnoughStorage
            }
        }
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        if MemoryLayout<UInt>.size == 8 {
            var value: UInt64 = 0
            guard decoder.deserializer.deserialize(&value) else {
                throw .outOfBounds
            }
            self = UInt(value)
        } else {
            var value: UInt32 = 0
            guard decoder.deserializer.deserialize(&value) else {
                throw .outOfBounds
            }
            self = UInt(value)
        }
    }
}

extension Int8: DDSCodable, DDSLoaningCodable {
    @inlinable
    public static var ddsInitialized: Int8 { .zero }

    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        do throws(DDSTypeDescriptor.LookupError) {
            return try DDSTypeDescriptor(lookup: "_int8_t")
        } catch {
            fatalError("Failed to lookup type descriptor for Int8: _int8_t")
        }
    }
    /// This will always throw a fatal error.
    /// - Warning: Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.
    @available(*, deprecated, message: "Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    public static var ddsTypeSupport: DDSTypeSupport {
        fatalError("Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        calculator.alignment += 1
        calculator.size += 1
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(self) else {
            throw .notEnoughStorage
        }
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        guard decoder.deserializer.deserialize(&self) else {
            throw .outOfBounds
        }
    }
}
extension UInt8: DDSCodable, DDSLoaningCodable {
    @inlinable
    public static var ddsInitialized: UInt8 { .zero }

    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        do throws(DDSTypeDescriptor.LookupError) {
            return try DDSTypeDescriptor(lookup: "_uint8_t")
        } catch {
            fatalError("Failed to lookup type descriptor for UInt8: _uint8_t")
        }
    }
    /// This will always throw a fatal error.
    /// - Warning: Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.
    @available(*, deprecated, message: "Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    public static var ddsTypeSupport: DDSTypeSupport {
        fatalError("Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        calculator.alignment += 1
        calculator.size += 1
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(self) else {
            throw .notEnoughStorage
        }
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        guard decoder.deserializer.deserialize(&self) else {
            throw .outOfBounds
        }
    }
}

extension Int16: DDSCodable, DDSLoaningCodable {
    @inlinable
    public static var ddsInitialized: Int16 { .zero }

    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        do throws(DDSTypeDescriptor.LookupError) {
            return try DDSTypeDescriptor(lookup: "_int16_t")
        } catch {
            fatalError("Failed to lookup type descriptor for Int16: _int16_t")
        }
    }
    /// This will always throw a fatal error.
    /// - Warning: Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.
    @available(*, deprecated, message: "Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    public static var ddsTypeSupport: DDSTypeSupport {
        fatalError("Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = 2 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 2)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(self) else {
            throw .notEnoughStorage
        }
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        guard decoder.deserializer.deserialize(&self) else {
            throw .outOfBounds
        }
    }
}
extension UInt16: DDSCodable, DDSLoaningCodable {
    @inlinable
    public static var ddsInitialized: UInt16 { .zero }

    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        do throws(DDSTypeDescriptor.LookupError) {
            return try DDSTypeDescriptor(lookup: "_uint16_t")
        } catch {
            fatalError("Failed to lookup type descriptor for UInt16: _uint16_t")
        }
    }
    /// This will always throw a fatal error.
    /// - Warning: Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.
    @available(*, deprecated, message: "Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    public static var ddsTypeSupport: DDSTypeSupport {
        fatalError("Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = 2 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 2)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(self) else {
            throw .notEnoughStorage
        }
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        guard decoder.deserializer.deserialize(&self) else {
            throw .outOfBounds
        }
    }
}

extension Int32: DDSCodable, DDSLoaningCodable {
    @inlinable
    public static var ddsInitialized: Int32 { .zero }

    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        do throws(DDSTypeDescriptor.LookupError) {
            return try DDSTypeDescriptor(lookup: "_int32_t")
        } catch {
            fatalError("Failed to lookup type descriptor for Int32: _int32_t")
        }
    }
    /// This will always throw a fatal error.
    /// - Warning: Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.
    @available(*, deprecated, message: "Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    public static var ddsTypeSupport: DDSTypeSupport {
        fatalError("Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = 4 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(self) else {
            throw .notEnoughStorage
        }
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        guard decoder.deserializer.deserialize(&self) else {
            throw .outOfBounds
        }
    }
}
extension UInt32: DDSCodable, DDSLoaningCodable {
    @inlinable
    public static var ddsInitialized: UInt32 { .zero }

    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        do throws(DDSTypeDescriptor.LookupError) {
            return try DDSTypeDescriptor(lookup: "_uint32_t")
        } catch {
            fatalError("Failed to lookup type descriptor for UInt32: _uint32_t")
        }
    }
    /// This will always throw a fatal error.
    /// - Warning: Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.
    @available(*, deprecated, message: "Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    public static var ddsTypeSupport: DDSTypeSupport {
        fatalError("Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = 4 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(self) else {
            throw .notEnoughStorage
        }
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        guard decoder.deserializer.deserialize(&self) else {
            throw .outOfBounds
        }
    }
}

extension Int64: DDSCodable, DDSLoaningCodable {
    @inlinable
    public static var ddsInitialized: Int64 { .zero }

    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        do throws(DDSTypeDescriptor.LookupError) {
            return try DDSTypeDescriptor(lookup: "_int64_t")
        } catch {
            fatalError("Failed to lookup type descriptor for Int64: _int64_t")
        }
    }
    /// This will always throw a fatal error.
    /// - Warning: Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.
    @available(*, deprecated, message: "Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    public static var ddsTypeSupport: DDSTypeSupport {
        fatalError("Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = 8 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: calculator.align64)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(self) else {
            throw .notEnoughStorage
        }
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        guard decoder.deserializer.deserialize(&self) else {
            throw .outOfBounds
        }
    }
}
extension UInt64: DDSCodable, DDSLoaningCodable {
    @inlinable
    public static var ddsInitialized: UInt64 { .zero }

    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        do throws(DDSTypeDescriptor.LookupError) {
            return try DDSTypeDescriptor(lookup: "_uint64_t")
        } catch {
            fatalError("Failed to lookup type descriptor for UInt64: _uint64_t")
        }
    }
    /// This will always throw a fatal error.
    /// - Warning: Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.
    @available(*, deprecated, message: "Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    public static var ddsTypeSupport: DDSTypeSupport {
        fatalError("Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = 8 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: calculator.align64)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(self) else {
            throw .notEnoughStorage
        }
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        guard decoder.deserializer.deserialize(&self) else {
            throw .outOfBounds
        }
    }
}

extension Float: DDSCodable, DDSLoaningCodable {
    @inlinable
    public static var ddsInitialized: Float { .nan }

    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        do throws(DDSTypeDescriptor.LookupError) {
            return try DDSTypeDescriptor(lookup: "_float")
        } catch {
            fatalError("Failed to lookup type descriptor for Float: _float")
        }
    }
    /// This will always throw a fatal error.
    /// - Warning: Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.
    @available(*, deprecated, message: "Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    public static var ddsTypeSupport: DDSTypeSupport {
        fatalError("Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = 4 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(self) else {
            throw .notEnoughStorage
        }
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        guard decoder.deserializer.deserialize(&self) else {
            throw .outOfBounds
        }
    }
}
extension Double: DDSCodable, DDSLoaningCodable {
    @inlinable
    public static var ddsInitialized: Double { .nan }

    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        do throws(DDSTypeDescriptor.LookupError) {
            return try DDSTypeDescriptor(lookup: "_double")
        } catch {
            fatalError("Failed to lookup type descriptor for Double: _double")
        }
    }
    /// This will always throw a fatal error.
    /// - Warning: Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.
    @available(*, deprecated, message: "Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    public static var ddsTypeSupport: DDSTypeSupport {
        fatalError("Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = 8 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: calculator.align64)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(self) else {
            throw .notEnoughStorage
        }
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        guard decoder.deserializer.deserialize(&self) else {
            throw .outOfBounds
        }
    }
}
extension Float80: DDSCodable, DDSLoaningCodable {
    @inlinable
    public static var ddsInitialized: Float80 { .nan }

    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        do throws(DDSTypeDescriptor.LookupError) {
            return try DDSTypeDescriptor(lookup: "_longdouble")
        } catch {
            fatalError("Failed to lookup type descriptor for Float80: _longdouble")
        }
    }
    /// This will always throw a fatal error.
    /// - Warning: Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.
    @available(*, deprecated, message: "Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    public static var ddsTypeSupport: DDSTypeSupport {
        fatalError("Primitive types cannot be used as topic types. Wrap the primitive in a struct to use it as a topic type.")
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = 16 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: calculator.align64)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        guard encoder.serializer.serialize(self) else {
            throw .notEnoughStorage
        }
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        guard decoder.deserializer.deserialize(&self) else {
            throw .outOfBounds
        }
    }
}
