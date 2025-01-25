/**
 * StatusMask.swift
 * _FastDDSShims
 * 
 * Created by Hunter Baker on 1/21/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
public import _CFastDDS

extension StatusMask: OptionSet {
    @inlinable
    @inline(__always)
    public init(rawValue: UInt32) {
        self.init(rawValue)
    }

    @inlinable
    @inline(__always)
    public var rawValue: UInt32 {
        StatusMask_rawValue(self)
    }
}
