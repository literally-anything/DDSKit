/**
 * FastDDSSetup.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/28/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import Logging
internal import _CFastDDS

/// A struct that sets up the FastDDS library and holds the intenral logger.
internal struct FastDDSSetup {
    /// The logger passed to the FastDDS library.
    private static let logger = Logger(label: "eprosima.FastDDS")

    /// Sets up the FastDDS library.
    /// Provides the logger callback and sets up some internal FastDDS settings.
    /// - Throws: `DDSError` if the setup fails.
    internal static func setup() throws(DDSError) {
        try FastDDSErrorCode.checkThrowInternal(FastDDS.setup { levelNumber, message, category, file, function, line in
            let level: Logger.Level
            switch levelNumber {
                case 0:
                    level = .debug
                case 1:
                    level = .warning
                default:
                    level = .error
            }
            FastDDSSetup.logger.log(
                level: level,
                "\(String(cString: message))",
                source: "FastDDS.\(category != nil ? String(cString: category!) : "")",
                file: file != nil ? String(cString: file!) : "",
                function: function != nil ? String(cString: function!) : "",
                line: UInt(line)
            )
        })
    }
}
