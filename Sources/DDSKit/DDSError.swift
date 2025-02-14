/**
 * DDSError.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 8/08/2024
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

@available(*, deprecated)
public enum DDSKitError: Error {
    case SynchronizationError
}

/// An error in DDSKit
public enum DDSError: Error {
    /// An error during the initialization of an entity.
    /// This does not have to be thrown from an initializer. Some entities are lazily initialized, so this could be thrown when the entity is first used.
    /// - Parameter FastDDSEntityType: The type of FastDDS entity that failed to initialize.
    case initializationError(from: FastDDSEntityType)

    /// An error during the destruction of an entity.
    /// This error is never thrown. It is only printed in a fatalError.
    /// - Parameter FastDDSEntityType: The type of FastDDS entity that failed to destroy.
    /// - Parameter FastDDSErrorCode: The error code returned from the DDS API.
    case destructionError(from: FastDDSEntityType, FastDDSErrorCode)

    /// An error while registering a type with the DDS API.
    /// - Parameter DDSTypeError: The error that occurred while registering the type.
    case dataTypeError(DDSTypeError)

    /// An error while publishing data.
    /// - Parameter FastDDSErrorCode: The error code returned from the DDS API.
    case publishError(FastDDSErrorCode)
}

/// A type of FastDDS entity.
public enum FastDDSEntityType: Sendable {
    case participant
    case topic
    case publisher
    case dataWriter
    case subscriber
    case dataReader
}

/// An error code from the DDS API.
public enum FastDDSErrorCode: Int32, Error, Sendable {
    case unknown = 1
    case unsupported = 2
    case badParameter = 3
    case preconditionFailed = 4
    case outOfResources = 5
    case notEnabled = 6
    case immutablePolicy = 7
    case inconsistentPolicy = 8
    case timeout = 9
    case noData = 10
    case illegalOperation = 11

    @usableFromInline
    internal static func check(_ code: Int32) -> FastDDSErrorCode? {
        guard code == eprosima.fastdds.dds.RETCODE_OK else {
            let error = FastDDSErrorCode(rawValue: code) ?? .unknown
            assert(
                ![.unsupported, .badParameter, .notEnabled, .immutablePolicy, .inconsistentPolicy, .illegalOperation].contains(error),
                "\(error) occurred. This is probably a DDSKit library bug."
            )
            return error
        }
        return nil
    }

    @usableFromInline
    internal static func checkThrow(_ code: Int32) throws(FastDDSErrorCode) {
        let error = check(code)
        if let error {
            throw error
        }
    }
}

/// An error while registering a type with the DDS API.
public enum DDSTypeError: Error {
    /// The name returned from the TypeSupport object has no characters.
    case invalidName
    /// A different type has already been registered with the same name.
    case alreadyRegistered
}
