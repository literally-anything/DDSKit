/**
 * DDSError.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 8/08/2024
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

/// An error in DDSKit
public enum DDSError: Error {
    /// Thrown when an operation fails because the system is out of memory.
    case outOfMemory

    /// Thrown when an operation times out.
    case timeout

    /// Thrown when a fastdds operation fails because of what is likely a library bug.
    case internalError(code: FastDDSErrorCode, from: FastDDSEntityType, file: StaticString, function: StaticString, line: UInt, column: UInt)

    /// Thrown when an operation fails for an unknown reason.
    /// - Parameter FastDDSErrorCode: The error code returned from the DDS API.
    case unknownError(from: FastDDSEntityType, FastDDSErrorCode?)

    /// Thrown when the library fails to load an XML profile.
    /// - Parameter name: The name of the profile that failed to load.
    case profileError(name: String, FastDDSErrorCode)

    /// An error during the initialization of an entity.
    /// This does not have to be thrown from an initializer. Some entities are lazily initialized, so this could be thrown when the entity is first used.
    /// - Parameter FastDDSEntityType: The type of FastDDS entity that failed to initialize.
    case initializationError(from: FastDDSEntityType)

    /// An error during the destruction of an entity.
    /// Note: This error is never thrown. It is only printed in a fatalError.
    /// - Parameters:
    ///   - from: The type of FastDDS entity that failed to destroy.
    ///   - FastDDSErrorCode: The error code returned from the DDS API.
    case destructionError(from: FastDDSEntityType, FastDDSErrorCode)

    /// An error while registering a type with the DDS API.
    /// - Parameter DDSTypeError: The error that occurred while registering the type.
    case dataTypeError(DDSTypeError)

    /// An error while publishing data.
    /// - Parameter FastDDSErrorCode: The error code returned from the DDS API.
    case publishError(FastDDSErrorCode)

    /// A type of FastDDS entity.
    public enum FastDDSEntityType: Sendable {
        /// Represents an unknown entity type.
        case unknown
        /// Represents a participant in the DDS.
        case participant
        /// Represents a topic in the DDS.
        case topic
        /// Represents a publisher in the DDS. This is part of a participant in the DDSKit API.
        case publisher
        /// Represents a data writer on a topic. This is represented as a publisher in the DDSKit API.
        case dataWriter
        /// Represents a subscriber in the DDS. This is part of a participant in the DDSKit API.
        case subscriber
        /// Represents a data reader on a topic. This is represented as a subscriber in the DDSKit API.
        case dataReader
    }
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

    /// Checks if the error code is not RETCODE_OK and returns the error code if it is not.
    /// - Parameter code: The error code to check.
    /// - Returns: The error code if it is not RETCODE_OK.
    @usableFromInline
    internal static func check(_ code: Int32) -> FastDDSErrorCode? {
        guard code == eprosima.fastdds.dds.RETCODE_OK else {
            return FastDDSErrorCode(rawValue: code) ?? .unknown
        }
        return nil
    }

    /// Throws a user error based on the error code.
    /// - Parameters:
    ///   - error: The error code to throw.
    ///   - entity: The entity type that the error occurred on.
    /// - Throws: The error that corresponds to the error code.
    @usableFromInline
    internal static func throwUser(_ error: FastDDSErrorCode, from entity: DDSError.FastDDSEntityType = .unknown) throws(DDSError) {
        assert(
            ![.unsupported, .badParameter, .notEnabled, .immutablePolicy, .inconsistentPolicy, .illegalOperation].contains(error),
            "\(error) occurred. This is probably a DDSKit library bug."
        )
        switch error {
            case .outOfResources:
                throw .outOfMemory
            case .timeout:
                throw .timeout
            default:
                throw .unknownError(from: entity, error)
        }
    }

    /// Checks if the error code is not RETCODE_OK and throws a user error if it is not.
    /// - Parameters:
    ///   - code: The error code to check.
    ///   - entity: The entity type that the error occurred on.
    /// - Throws: The error that corresponds to the error code.
    @usableFromInline
    internal static func checkThrow(_ code: Int32, from entity: DDSError.FastDDSEntityType = .unknown) throws(DDSError) {
        let error = check(code)
        if let error {
            try throwUser(error, from: entity)
        }
    }

    /// Checks if the error code is not RETCODE_OK and throws an internal error if it is not.
    /// - Parameters:
    ///   - code: The error code to check.
    ///   - entity: The entity type that the error occurred on.
    ///   - file: The file that the error occurred in.
    ///   - function: The function that the error occurred in.
    ///   - line: The line that the error occurred on.
    ///   - column: The column that the error occurred on.
    /// - Throws: The error that corresponds to the error code.
    @usableFromInline
    internal static func checkThrowInternal(
        _ code: Int32, from entity: DDSError.FastDDSEntityType = .unknown,
        file: StaticString = #file, function: StaticString = #function, line: UInt = #line, column: UInt = #column
    ) throws(DDSError) {
        let error = check(code)
        if let error {
            switch error {
                case .outOfResources:
                    throw .outOfMemory
                case .timeout:
                    throw .timeout
                default:
                    throw .internalError(code: error, from: entity, file: file, function: function, line: line, column: column)
            }
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
