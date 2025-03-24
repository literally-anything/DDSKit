/**
 * TypeDescriptor.swift
 * DDSCodable
 * 
 * Created by Hunter Baker on 3/16/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS
internal import Dispatch

/// A descriptor for a DDS type.
public struct DDSTypeDescriptor: Sendable, CustomStringConvertible {
    /// The internal xtypes identifier pair for the type.
    internal let identifier: FastDDS.Types.TypeIdentifierPair
    /// The registered name of the type.
    public let name: String

    /// A lock for type building.
    internal static let lock = DispatchSemaphore(value: 1)
    /// A flag to indicate if the type is currently being built on this task so I don't lock twice.
    @TaskLocal
    internal static var isBuilding = false

    /// Creates a new type descriptor with the given identifier and name.
    /// - Parameters:
    ///   - identifier: The internal xtypes identifier pair for the type.
    ///   - name: The registered name of the type.
    internal init(identifier: FastDDS.Types.TypeIdentifierPair, name: String) {
        self.identifier = identifier
        self.name = name
    }

    /// Creates a new type descriptor by looking up the type with the given name.
    /// - Parameter name: The name of the type to look up.
    /// - Throws: A `LookupError` if the type cannot be found.
    public init?(lookup name: String) {
        var identifier = FastDDS.Types.TypeIdentifierPair()
        guard FastDDS.Types.getIdentifiersForName(name: .init(name), identifiers: &identifier) else {
            return nil
        }
        self.identifier = identifier

        self.name = name
    }

    public var description: String {
        "DDSTypeDescriptor(name: \(name))"
    }
}
