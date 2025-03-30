/**
 * ArrayTypeBuilder.swift
 * TypeBuilders
 * 
 * Created by Hunter Baker on 3/24/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

/// A builder for creating DDS array and sequence types.
internal struct DDSArrayTypeBuilder {
    /// The type of the elements in the array or sequence.
    internal let elementType: DDSTypeDescriptor
    /// The size of the array. If `nil`, the type is a sequence (unbounded).
    internal let size: UInt32?

    /// Creates a new array type builder with the given element type and size.
    /// - Parameters:
    ///   - elementType: The type descriptor of the element type in the array or sequence.
    ///   - size: The size of the array. If `nil`, the type is a sequence (unbounded).
    internal init(elementType: DDSTypeDescriptor, size: UInt32?) {
        self.elementType = elementType
        self.size = size
    }

    /// The name of the array or sequence type using the standard FastDDS naming convention.
    internal var name: String {
        var elementName = elementType.name
        if elementName.starts(with: "_") { elementName.removeFirst() } // We don't want the leading underscore in private names.

        if let size {
            return "anonymous_array_\(elementName)_\(size)"
        } else {
            return "anonymous_sequence_\(elementName)_unbounded"
        }
    }

    /// Builds and registers the array or sequence type.
    /// - Returns: The identifier pair for the array or sequence type.
    /// - Note: This method will throw a fatal error if the type cannot be created.
    internal func build() -> DDSTypeDescriptor {
        var identifier = FastDDS.Types.TypeIdentifierPair()

        if let size {
            let ret = if size <= UInt8.max {
                // When using a size that fits in a UInt8, we can use smaller bounds for the array.
                FastDDS.Types.createArray(name: .init(name), shape: [UInt8(size)], element: elementType.identifier, identifiers: &identifier)
            } else {
                FastDDS.Types.createArray(name: .init(name), shape: [size], element: elementType.identifier, identifiers: &identifier)
            }
            guard ret else {
                fatalError("Failed to build DDS array type: \(name). Another type with the same name already exists.")
            }
        } else {
            let ret = FastDDS.Types.createSequence(name: .init(name), element: elementType.identifier, identifiers: &identifier)
            guard ret else {
                fatalError("Failed to build DDS sequence type: \(name). Another type with the same name already exists.")
            }
        }

        return DDSTypeDescriptor(identifier: identifier, name: name)
    }
}

extension DDSTypeDescriptor {
    /// Creates a new array type descriptor by building it with the given element type and size.
    /// - Parameters:
    ///   - elementType: The type descriptor of the element type in the array or sequence.
    ///   - size: The size of the array. If `nil`, the type is a sequence (unbounded).
    /// - Returns: The array or sequence type descriptor.
    /// - Note: This method will throw a fatal error if the type cannot be created.
    @usableFromInline
    internal static func createArray(of elementType: DDSTypeDescriptor, size: UInt32? = nil) -> DDSTypeDescriptor {
        if !DDSTypeDescriptor.isBuilding { DDSTypeDescriptor.lock.wait() }
        defer { if !DDSTypeDescriptor.isBuilding { DDSTypeDescriptor.lock.signal() } }
        return DDSTypeDescriptor.$isBuilding.withValue(true) {
            var builder = DDSArrayTypeBuilder(elementType: elementType, size: size)

            #if !DEBUG
                var identifier = FastDDS.Types.TypeIdentifierPair()
                if FastDDS.Types.getIdentifiersForName(name: .init(builder.name), identifiers: &identifier) {
                    return DDSTypeDescriptor(identifier: identifier, name: builder.name)
                }
            #endif

            return builder.build()
        }
    }
}
