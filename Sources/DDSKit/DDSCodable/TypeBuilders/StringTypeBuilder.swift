/**
 * StringTypeBuilder.swift
 * TypeBuilders
 * 
 * Created by Hunter Baker on 3/18/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

/// A builder for creating DDS type descriptors for strings.
public struct DDSStringTypeBuilder: ~Copyable {
    let size: Int?
    // let isWide: Bool

    /// Creates a new string type builder with the given name.
    /// - Parameters:
    ///   - size: The size of the string. If `nil`, the string is unbounded.
    internal init(size: Int?) {
        self.size = size
    }

    /// The name of the string type using the standart FastDDS naming convention.
    private var name: String {
        let sizeText = if let size { String(size) } else { "unbounded" }
        return "anonymous_string_\(sizeText)"
    }

    /// Builds and registers the string type.
    /// - Returns: The identifier pair for the string type.
    /// - Note: This method will throw a fatal error if the type cannot be created.
    internal func build() -> DDSTypeDescriptor {
        var identifier = FastDDS.Types.TypeIdentifierPair()

        let ret = FastDDS.Types.createString(name: .init(name), length: UInt32(size ?? 0), isWide: false, identifiers: &identifier)
        guard ret else {
            fatalError("Failed to build DDS string type: \(name). Another type with the same name already exists.")
        }

        return DDSTypeDescriptor(identifier: identifier, name: name)        
    }
}

extension DDSTypeDescriptor {
    /// Creates a new string type descriptor with the given size.
    /// - Parameters:
    ///   - stringSize: The size of the string. If `nil`, the string is unbounded.
    public init(stringSize: Int?) {
        var identifier = FastDDS.Types.TypeIdentifierPair()

        // Lock the building process to avoid data races, but no need to lock if the task we are running on is already building this type.
        if !DDSTypeDescriptor.isBuilding { DDSTypeDescriptor.lock.wait() }
        defer { if !DDSTypeDescriptor.isBuilding { DDSTypeDescriptor.lock.signal() } }
        self = DDSTypeDescriptor.$isBuilding.withValue(true) {
            var builder = DDSStringTypeBuilder(size: stringSize)

            // When in debug mode, we always build the type, so we can ensure that the type is same as the one that is already registered.
            #if !DEBUG
                if FastDDS.Types.getIdentifiersForName(name: .init(builder.name), identifiers: &identifier) {
                    return DDSTypeDescriptor(identifier: identifier, name: builder.name)
                }
            #endif

            return builder.build()
        }
    }
}
