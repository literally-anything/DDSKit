/**
 * HelloWorldGood.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 8/18/2024
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
import CxxStdlib
import enum _CFastDDS.fastdds

struct HelloWorldGood : Sendable, Equatable, IDLType {
    public var index: UInt32 {
        get {
            fastdds._DynamicTypes.getUInt32(_data, 0)
        }
        set(newValue) {
            fastdds._DynamicTypes.setUInt32(_data, 0, newValue)
        }
    }
    public var message: String {
        get {
            String(fastdds._DynamicTypes.getString(_data, 1))
        }
        set(newValue) {
            fastdds._DynamicTypes.setString(_data, 1, .init(newValue))
        }
    }

    public var _data: fastdds._DynamicTypes.DynamicData

    public var hello = 0.5

    init() {
        _data = fastdds._DynamicTypes.buildData(Self.type)
    }

    init(from data: fastdds._DynamicTypes.DynamicData) {
        _data = data
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return fastdds._DynamicTypes.dataEqual(lhs._data, rhs._data)
    }

    private static func _buildType() -> fastdds._DynamicTypes.DynamicTypeContainer {
        var good: Bool = false
        let builder = fastdds._DynamicTypes.createStruct(&good, "ty")
        guard good else {
            preconditionFailure("failed to create HelloWorldGood")
        }

        try! FastDDSError.check(code: fastdds._DynamicTypes.createUInt32(builder, "index"))
        try! FastDDSError.check(code: fastdds._DynamicTypes.createString(builder, "message"))

        return fastdds._DynamicTypes.buildType(builder)
    }
    public static let type = _buildType()
    public static let typeSupport = fastdds._DynamicTypes.buildTypeSupport(type)
}
