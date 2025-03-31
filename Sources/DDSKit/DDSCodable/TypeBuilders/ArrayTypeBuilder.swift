/**
 * ArrayTypeBuilder.swift
 * TypeBuilders
 * 
 * Created by Hunter Baker on 3/24/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

extension DDSTypeDescriptor {
    /// Creates a new unbounded array type (sequence) descriptor by building it with the given element type.
    /// - Parameters:
    ///   - elementType: The type descriptor of the element type in the array or sequence.
    ///   - primitive: Whether the element is a primitive type.
    /// - Returns: The sequence type descriptor.
    /// - Note: This method will throw a fatal error if the type cannot be created.
    @usableFromInline
    internal static func createUnboundedArray(of elementType: DDSTypeDescriptor, primitive: Bool) -> DDSTypeDescriptor {
        var elementName = elementType.name
        if elementName.starts(with: "_") { elementName.removeFirst() } // We don't want the leading underscore in primitive names.

        // Figure out what the type name should be using the standard FastDDS naming convention.
        let name = "anonymous_sequence_\(elementName)_unbounded"

        if !DDSTypeDescriptor.isBuilding { DDSTypeDescriptor.lock.wait() }
        defer { if !DDSTypeDescriptor.isBuilding { DDSTypeDescriptor.lock.signal() } }
        return DDSTypeDescriptor.$isBuilding.withValue(true) {
            var identifier = FastDDS.Types.TypeIdentifierPair()

            let foundExistingType = FastDDS.Types.getIdentifiersForName(name: .init(name), identifiers: &identifier)

            // If the type is not found, we need to build it.
            if !foundExistingType {
                let ret = FastDDS.Types.createSequence(name: .init(name), element: elementType.identifier, identifiers: &identifier)
                guard ret else {
                    fatalError("Failed to build DDS sequence type: \(name). Another type with the same name already exists.")
                }
            }

            return DDSTypeDescriptor(
                identifier: identifier, name: name,
                isBounded: false, isPlain: false
            ) { initialAlignment in
                var alignment = initialAlignment

                if !primitive {
                    alignment += 4 &+ DDSSizeCalculator.getAlignment(currentAlignment: alignment, dataSize: 4)
                }
                alignment += 4 &+ DDSSizeCalculator.getAlignment(currentAlignment: alignment, dataSize: 4)

                return alignment - initialAlignment
            }
        }
    }

    /// Creates a new array type descriptor by building it with the given element type and size.
    /// - Parameters:
    ///   - elementType: The type descriptor of the element type in the array or sequence.
    ///   - primitive: Whether the element is a primitive type.
    ///   - shape: The shape of the array.
    /// - Returns: The array type descriptor.
    /// - Note: This method will throw a fatal error if the type cannot be created.
    @usableFromInline
    internal static func createArray(of elementType: DDSTypeDescriptor, primitive: Bool, shape: [UInt32]) -> DDSTypeDescriptor {
        assert(shape.count > 0, "Array shape must be non-empty")
        assert(shape.allSatisfy { $0 > 0 }, "Array shape elements must be greater than 0")

        var elementName = elementType.name
        if elementName.starts(with: "_") { elementName.removeFirst() } // We don't want the leading underscore in primitive names.

        // Figure out what the type name should be using the standard FastDDS naming convention.
        let name = "anonymous_array_\(elementName)_\(shape.map({ String($0) }).joined(separator: "_"))"

        if !DDSTypeDescriptor.isBuilding { DDSTypeDescriptor.lock.wait() }
        defer { if !DDSTypeDescriptor.isBuilding { DDSTypeDescriptor.lock.signal() } }
        return DDSTypeDescriptor.$isBuilding.withValue(true) {
            var identifier = FastDDS.Types.TypeIdentifierPair()

            var foundExistingType = false
            #if !DEBUG
                foundExistingType = FastDDS.Types.getIdentifiersForName(name: .init(name), identifiers: &identifier)
            #endif

            // If the type is not found, we need to build it.
            if !foundExistingType {
                // When using a size that fits in a UInt8, we can use UInt8 bounds for the array.
                let ret = if shape.allSatisfy({ $0 <= UInt8.max }) {
                    FastDDS.Types.createArray(name: .init(name), shape: .init(shape.map { UInt8($0) }), element: elementType.identifier, identifiers: &identifier)
                } else {
                    FastDDS.Types.createArray(name: .init(name), shape: .init(shape), element: elementType.identifier, identifiers: &identifier)
                }
                guard ret else {
                    fatalError("Failed to build DDS array type: \(name). Another type with the same name already exists.")
                }
            }

            return DDSTypeDescriptor(
                identifier: identifier, name: name,
                isBounded: elementType.isBounded, isPlain: elementType.isBounded && elementType.isPlain && primitive
            ) { initialAlignment in
                var alignment = initialAlignment

                if primitive {
                    alignment += 4 &+ DDSSizeCalculator.getAlignment(currentAlignment: alignment, dataSize: 4)
                }
                
                // Multiply all elements together to get the total size of the array.
                let totalSize: Int = shape.reduce(1) { $0 &* Int($1) }
                assert(totalSize > 0, "Array size must be greater than 0")

                alignment += elementType.calculateMaxSize(alignment)
                if totalSize > 1 {
                    let elementSizeAfterFirst = elementType.calculateMaxSize(alignment)
                    alignment += elementSizeAfterFirst &* (totalSize &- 1)
                }

                return alignment - initialAlignment
            }
        }
    }
}
