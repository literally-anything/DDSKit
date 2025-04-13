/**
 * TypeDescriptor.swift
 * DDSCodable
 *
 * Created by Hunter Baker on 3/16/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */

internal import Dispatch
internal import _CFastDDS

/// A descriptor for a DDS type.
public struct DDSTypeDescriptor: Sendable {
    /// The internal xtypes identifier pair for the type.
    internal let identifier: FastDDS.Types.TypeIdentifierPair
    /// The registered name of the type.
    public let name: String
    /// Whether the type is bounded or unbounded.
    public let isBounded: Bool
    /// Whether the serialization is plain or not (can be loaned).
    public let isPlain: Bool
    /// A closure that calculates the maximum size of the type.
    /// - Parameters:
    ///   - alignment: The alignment of the type.
    /// - Returns: The maximum size of the type.
    public let calculateMaxSize: @Sendable (Int) -> Int
    /// The maximum size of the type.
    public var maxSize: Int { calculateMaxSize(0) }

    /// A lock for type building.
    internal static let lock = DispatchSemaphore(value: 1)
    /// A flag to indicate if the type is currently being built on this task so I don't lock twice.
    @TaskLocal
    internal static var isBuilding = false

    /// Creates a new type descriptor with the given identifier and name.
    /// - Parameters:
    ///   - identifier: The internal xtypes identifier pair for the type.
    ///   - name: The registered name of the type.
    ///   - isBounded: Whether the type is bounded or unbounded.
    ///   - isPlain: Whether the serialization is plain or not (can be loaned).
    ///   - calculateMaxSize: A closure that calculates the maximum size of the type.
    internal init(
        identifier: FastDDS.Types.TypeIdentifierPair, name: String, isBounded: Bool, isPlain: Bool,
        calculateMaxSize: @escaping @Sendable (Int) -> Int
    ) {
        self.identifier = identifier
        self.name = name
        self.isBounded = isBounded
        self.isPlain = isPlain
        self.calculateMaxSize = calculateMaxSize
    }

    /// Creates a new type descriptor by looking up the type with the given name.
    /// - Parameters
    ///   - name: The name of the type to look up.
    ///   - isBounded: Whether the type is bounded. Defaults to `false`.
    ///   - isPlain: Whether the serialization is plain or not (can be loaned). Defaults to `false`.
    ///   - calculateMaxSize: A closure that calculates the maximum size of the type.
    /// - Throws: A `LookupError` if the type cannot be found.
    public init?(
        lookup name: String, isBounded: Bool = false, isPlain: Bool = false,
        calculateMaxSize: @escaping @Sendable (Int) -> Int
    ) {
        var identifier = FastDDS.Types.TypeIdentifierPair()
        guard FastDDS.Types.getIdentifiersForName(name: .init(name), identifiers: &identifier) else {
            return nil
        }
        self.identifier = identifier

        self.name = name
        self.isBounded = isBounded
        self.isPlain = isPlain
        self.calculateMaxSize = calculateMaxSize
    }
}

extension DDSTypeDescriptor: CustomStringConvertible {
    public var description: String {
        "DDSTypeDescriptor(name: \(name), isBounded: \(isBounded), isPlain: \(isPlain), maxSize: \(maxSize))"
    }
}
