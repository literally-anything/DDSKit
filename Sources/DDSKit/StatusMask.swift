/**
 * StatusMask.swift
 * _FastDDSShims
 * 
 * Created by Hunter Baker on 1/21/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

extension FastDDS.StatusMask: OptionSet {
    public init(rawValue: UInt32) {
        self.init(rawValue)
    }

    public var rawValue: UInt32 {
        FastDDS.StatusMaskHelpers.getRawValue(self)
    }
}
