/**
 * LogConsumerBase.swift
 * _FastDDSHelpers
 * 
 * Created by Hunter Baker on 1/23/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
public import Logging

public struct LogConsumerBase {
    public let logger = Logger(label: "eprosima.FastDDS")

    @inlinable
    @inline(__always)
    public init() {}

    @inlinable
    @inline(__always)
    public func info(_ message: String, _ category: String, _ file: String, _ function: String, _ line: UInt) {
        logger.info(
            "\(message)",
            metadata: [
                "category": "\(category)"
            ],
            source: "FastDDS",
            file: file,
            function: function,
            line: line
        )
    }

    @inlinable
    @inline(__always)
    public func warning(_ message: String, _ category: String, _ file: String, _ function: String, _ line: UInt) {
        logger.warning(
            "\(message)",
            metadata: [
                "category": "\(category)"
            ],
            source: "FastDDS",
            file: file,
            function: function,
            line: line
        )
    }

    @inlinable
    @inline(__always)
    public func error(_ message: String, _ category: String, _ file: String, _ function: String, _ line: UInt) {
        logger.error(
            "\(message)",
            metadata: [
                "category": "\(category)"
            ],
            source: "FastDDS",
            file: file,
            function: function,
            line: line
        )
    }
}
