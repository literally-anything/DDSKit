/**
 * ArrayTypeBuilder.swift
 * TypeBuilders
 * 
 * Created by Hunter Baker on 3/24/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

public struct DDSArrayTypeBuilder {
    let elementType: DDSTypeDescriptor
    let size: UInt32?

    internal init(elementType: DDSTypeDescriptor, size: UInt32?) {
        self.elementType = elementType
        self.size = size
    }

    internal var name: String {
        var elementName = elementType.name
        if elementName.starts(with: "_") { elementName.removeFirst() } // We don't want the leading underscore in private names.

        if let size {
            return "anonymous_array_\(elementName)_\(size)"
        } else {
            return "anonymous_sequence_\(elementName)_unbounded"
        }
    }

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
    public static func array(of elementType: DDSTypeDescriptor, size: UInt32? = nil) -> DDSTypeDescriptor {
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
