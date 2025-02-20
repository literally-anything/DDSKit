/**
 * DynamicType.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/19/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

public struct DynamicTypeDescription: Sendable {
    internal var type: FastDDS.DynamicTypes.DynamicTypeContainer
    internal var typeSupport: FastDDS.TypeSupportWrapper
}

public class DynamicTypeBuilder {
    private let builder: FastDDS.DynamicTypes.DynamicTypeBuilder

    public init(name: StaticString) {
        var success = false
        builder = FastDDS.DynamicTypes.createStruct(&success, name.utf8Start)
        if !success {
            preconditionFailure("Failed to create dynamic type")
        }
    }

    public func addBool(name: StaticString) -> Self {
        try! FastDDSErrorCode.checkThrow(FastDDS.DynamicTypes.createBool(builder, name.utf8Start))
        return self
    }
    public func addInt8(name: StaticString) -> Self {
        try! FastDDSErrorCode.checkThrow(FastDDS.DynamicTypes.createInt8(builder, name.utf8Start))
        return self
    }
    public func addUInt8(name: StaticString) -> Self {
        try! FastDDSErrorCode.checkThrow(FastDDS.DynamicTypes.createUInt8(builder, name.utf8Start))
        return self
    }
    public func addInt16(name: StaticString) -> Self {
        try! FastDDSErrorCode.checkThrow(FastDDS.DynamicTypes.createInt16(builder, name.utf8Start))
        return self
    }
    public func addUInt16(name: StaticString) -> Self {
        try! FastDDSErrorCode.checkThrow(FastDDS.DynamicTypes.createUInt16(builder, name.utf8Start))
        return self
    }
    public func addInt32(name: StaticString) -> Self {
        try! FastDDSErrorCode.checkThrow(FastDDS.DynamicTypes.createInt32(builder, name.utf8Start))
        return self
    }
    public func addUInt32(name: StaticString) -> Self {
        try! FastDDSErrorCode.checkThrow(FastDDS.DynamicTypes.createUInt32(builder, name.utf8Start))
        return self
    }
    public func addInt64(name: StaticString) -> Self {
        try! FastDDSErrorCode.checkThrow(FastDDS.DynamicTypes.createInt64(builder, name.utf8Start))
        return self
    }
    public func addUInt64(name: StaticString) -> Self {
        try! FastDDSErrorCode.checkThrow(FastDDS.DynamicTypes.createUInt64(builder, name.utf8Start))
        return self
    }
    public func addFloat32(name: StaticString) -> Self {
        try! FastDDSErrorCode.checkThrow(FastDDS.DynamicTypes.createFloat32(builder, name.utf8Start))
        return self
    }
    public func addFloat64(name: StaticString) -> Self {
        try! FastDDSErrorCode.checkThrow(FastDDS.DynamicTypes.createFloat64(builder, name.utf8Start))
        return self
    }
    public func addString(name: StaticString) -> Self {
        try! FastDDSErrorCode.checkThrow(FastDDS.DynamicTypes.createString(builder, name.utf8Start))
        return self
    }
    public func addString(name: StaticString, length: UInt32) -> Self {
        try! FastDDSErrorCode.checkThrow(FastDDS.DynamicTypes.createString(builder, name.utf8Start, length))
        return self
    }

    public func build() -> DynamicTypeDescription {
        let type = FastDDS.DynamicTypes.buildType(builder)
        let typeSupport = FastDDS.DynamicTypes.buildTypeSupport(type)

        return DynamicTypeDescription(type: type, typeSupport: typeSupport)
    }
}

public struct DynamicData: Sendable, Equatable {
    internal var raw: FastDDS.DynamicTypes.DynamicDataContainer

    public init(type: borrowing DynamicTypeDescription) {
        raw = FastDDS.DynamicTypes.DynamicDataContainer(type.type)
    }

    public static func == (lhs: borrowing DynamicData, rhs: borrowing DynamicData) -> Bool { // The compiler breaks when using Equatable
    // public static func equals (lhs: borrowing DynamicData, rhs: borrowing DynamicData) -> Bool {
        lhs.raw.equals(rhs.raw)
    }

    public func getBool(memberId: UInt32) -> Bool {
        FastDDS.DynamicTypes.getBool(raw, memberId)
    }
    public func getInt8(memberId: UInt32) -> Int8 {
        FastDDS.DynamicTypes.getInt8(raw, memberId)
    }
    public func getUInt8(memberId: UInt32) -> UInt8 {
        FastDDS.DynamicTypes.getUInt8(raw, memberId)
    }
    public func getInt16(memberId: UInt32) -> Int16 {
        FastDDS.DynamicTypes.getInt16(raw, memberId)
    }
    public func getUInt16(memberId: UInt32) -> UInt16 {
        FastDDS.DynamicTypes.getUInt16(raw, memberId)
    }
    public func getInt32(memberId: UInt32) -> Int32 {
        FastDDS.DynamicTypes.getInt32(raw, memberId)
    }
    public func getUInt32(memberId: UInt32) -> UInt32 {
        FastDDS.DynamicTypes.getUInt32(raw, memberId)
    }
    public func getInt64(memberId: UInt32) -> Int64 {
        FastDDS.DynamicTypes.getInt64(raw, memberId)
    }
    public func getUInt64(memberId: UInt32) -> UInt64 {
        FastDDS.DynamicTypes.getUInt64(raw, memberId)
    }
    public func getFloat32(memberId: UInt32) -> Float32 {
        FastDDS.DynamicTypes.getFloat32(raw, memberId)
    }
    public func getFloat64(memberId: UInt32) -> Float64 {
        FastDDS.DynamicTypes.getFloat64(raw, memberId)
    }
    public func getString(memberId: UInt32) -> String {
        .init(FastDDS.DynamicTypes.getString(raw, memberId))
    }

    public func setBool(memberId: UInt32, _ value: Bool) {
        FastDDS.DynamicTypes.setBool(raw, memberId, value)
    }
    public func setInt8(memberId: UInt32, _ value: Int8) {
        FastDDS.DynamicTypes.setInt8(raw, memberId, value)
    }
    public func setUInt8(memberId: UInt32, _ value: UInt8) {
        FastDDS.DynamicTypes.setUInt8(raw, memberId, value)
    }
    public func setInt16(memberId: UInt32, _ value: Int16) {
        FastDDS.DynamicTypes.setInt16(raw, memberId, value)
    }
    public func setUInt16(memberId: UInt32, _ value: UInt16) {
        FastDDS.DynamicTypes.setUInt16(raw, memberId, value)
    }
    public func setInt32(memberId: UInt32, _ value: Int32) {
        FastDDS.DynamicTypes.setInt32(raw, memberId, value)
    }
    public func setUInt32(memberId: UInt32, _ value: UInt32) {
        FastDDS.DynamicTypes.setUInt32(raw, memberId, value)
    }
    public func setInt64(memberId: UInt32, _ value: Int64) {
        FastDDS.DynamicTypes.setInt64(raw, memberId, value)
    }
    public func setUInt64(memberId: UInt32, _ value: UInt64) {
        FastDDS.DynamicTypes.setUInt64(raw, memberId, value)
    }
    public func setFloat32(memberId: UInt32, _ value: Float32) {
        FastDDS.DynamicTypes.setFloat32(raw, memberId, value)
    }
    public func setFloat64(memberId: UInt32, _ value: Float64) {
        FastDDS.DynamicTypes.setFloat64(raw, memberId, value)
    }
    public func setString(memberId: UInt32, _ value: String) {
        FastDDS.DynamicTypes.setString(raw, memberId, .init(value))
    }
}
