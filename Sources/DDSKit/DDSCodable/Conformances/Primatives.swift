/**
 * Primatives.swift
 * DDSCodable
 * 
 * Created by Hunter Baker on 3/09/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */

extension Bool: DDSCodable {
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

extension Int: DDSCodable {
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
extension UInt: DDSCodable {
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

extension Int8: DDSCodable {
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
extension UInt8: DDSCodable {
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

extension Int16: DDSCodable {
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
extension UInt16: DDSCodable {
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

extension Int32: DDSCodable {
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
extension UInt32: DDSCodable {
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

extension Int64: DDSCodable {
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
extension UInt64: DDSCodable {
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

extension Float: DDSCodable {
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
extension Double: DDSCodable {
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
extension Float80: DDSCodable {
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
