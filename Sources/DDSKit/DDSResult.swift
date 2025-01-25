/**
 * DDSResult.swift
 * _FastDDSShims
 * 
 * Created by Hunter Baker on 1/21/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
package enum FastDDSError: Int32, Error {
    case error = 1
    case unsupported = 2
    case badParameter = 3
    case preconditionNotMet = 4
    case outOfResources = 5
    case notEnabled = 6
    case immutablePolicy = 7
    case inconsistentPolicy = 8
    case alreadyDeleted = 9
    case timeout = 10
    case noData = 11
    case illegalOperation = 12

    package static let OK: Int32 = 0

    @inlinable
    package static func check(code ret: Int32) throws {
        if (ret != OK) {
            let e = FastDDSError(rawValue: ret)
            if let e {
                throw e
            }
        }
    }
}
