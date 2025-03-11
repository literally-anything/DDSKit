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
}
extension Int8: DDSCodable {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        calculator.alignment += 1
        calculator.size += 1
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}
}
extension UInt8: DDSCodable {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        calculator.alignment += 1
        calculator.size += 1
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}
}
extension Int16: DDSCodable {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = 2 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 2)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}
}
extension UInt16: DDSCodable {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = 2 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 2)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}
}
extension Int32: DDSCodable {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = 4 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}
}
extension UInt32: DDSCodable {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = 4 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}
}
extension Int64: DDSCodable {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = 8 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: calculator.align64)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}
}
extension UInt64: DDSCodable {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = 8 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: calculator.align64)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}
}
extension Float: DDSCodable {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = 4 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: 4)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}
}
extension Double: DDSCodable {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = 8 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: calculator.align64)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}
}
extension Float80: DDSCodable {
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        let calculatedSize = 16 &+ DDSSizeCalculator.getAlignment(currentAlignment: calculator.alignment, dataSize: calculator.align64)
        calculator.alignment += calculatedSize
        calculator.size += calculatedSize
    }
    public var ddsSize: UInt32 {DDSSizeCalculator.calculateSize(primitive: self)}
}
