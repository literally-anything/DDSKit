/**
 * StructTypeBuilder.swift
 * TypeBuilders
 * 
 * Created by Hunter Baker on 3/18/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

/// A builder for creating DDS type descriptors.
public struct DDSStructTypeBuilder: ~Copyable {
    /// The internal info for the type builder.
    internal var info = FastDDS.Types.StructCreateInfo()
    /// The name of the type being built.
    internal var name: String

    /// Creates a new type builder with the given name.
    /// - Parameter name: The name of the type to build. This name is only local and needs to be unique, so it's best to just make it very specific.
    /// - Note: This method will throw a fatal error if the type cannot be created.
    internal init(name: String) {
        self.name = name
        guard FastDDS.Types.createStruct(name: .init(name), info: &info) else {
            fatalError("Failed to create DDS type builder: \(name). This is likely a library bug.")
        }
    }

    /// Adds a member to the type being built using the given descriptor.
    /// - Parameters:
    ///   - descriptor: The descriptor of the type to add as a member.
    ///   - memberName: The name of the member.
    ///   - memberId: The id of the member.
    ///   - optional: Whether the member is optional. Defaults to `false`.
    /// - Note: This method will throw a fatal error if the member type cannot be added.
    public mutating func addMember(descriptor: DDSTypeDescriptor, name memberName: String, memberId: UInt32, optional: Bool = false) {
        guard FastDDS.Types.addStructMember(
            info: &info, identifiers: descriptor.identifier, name: .init(memberName), id: memberId, isOptional: optional, isKey: false
        ) else {
            fatalError("Failed to add member \"\(memberName)\" to DDS type builder: \(name). This is likely either two members with the same id or a library bug.")
        }
    }

    /// Adds a member to the type being built using the given `DDSCodable` type.
    /// - Parameters:
    ///   - type: The type of the member.
    ///   - memberName: The name of the member.
    ///   - memberId: The id of the member.
    /// - Note: This method will throw a fatal error if the member type cannot be added.
    @inlinable
    public mutating func addMember<T: DDSCodable>(type: T.Type, name memberName: String, memberId: UInt32) {
        addMember(descriptor: T.ddsTypeDescriptor, name: memberName, memberId: memberId, optional: false)
    }
    /// Adds a member to the type being built using the given optional `DDSCodable` type.
    /// - Parameters:
    ///   - type: The optional type of the member.
    ///   - memberName: The name of the member.
    ///   - memberId: The id of the member.
    /// - Note: This method will throw a fatal error if the member type cannot be added.
    @inlinable
    public mutating func addMember<T: DDSCodable>(type: T?.Type, name memberName: String, memberId: UInt32) {
        addMember(descriptor: T.ddsTypeDescriptor, name: memberName, memberId: memberId, optional: true)
    }

    /// Finishes building and registering the type and returns the built descriptor.
    /// - Returns: The built descriptor.
    /// - Note: This method will throw a fatal error if the type cannot be built.
    internal func build() -> DDSTypeDescriptor {
        var identifiers = FastDDS.Types.TypeIdentifierPair()

        let ret = FastDDS.Types.finishStruct(info: info, name: .init(name), identifiers: &identifiers)
        switch ret {
            case eprosima.fastdds.dds.RETCODE_OK: break
            case eprosima.fastdds.dds.RETCODE_BAD_PARAMETER:
                fatalError("Failed to build DDS type: \(name). Another type with the same name already exists.")
            default:
                fatalError("Failed to build DDS type: \(name). Some internal error occured while building: \(ret).")
        }

        return DDSTypeDescriptor(identifier: identifiers, name: .init(name))
    }
}

extension DDSTypeDescriptor {
    /// Creates a new struct type descriptor by building it with the given name and build closure.
    /// The closure is only called the first time the type is created. All subsequent calls will look up the type by name.
    /// - Parameters:
    ///   - name: The name of the type to build.
    ///   - build: The closure to build the type with.
    public static func createStruct(name: String, build: (inout DDSStructTypeBuilder) -> Void) -> DDSTypeDescriptor {
        // Lock the building process to avoid data races, but no need to lock if the task we are running on is already building this type.
        if !DDSTypeDescriptor.isBuilding { DDSTypeDescriptor.lock.wait() }
        defer { if !DDSTypeDescriptor.isBuilding { DDSTypeDescriptor.lock.signal() } }
        return DDSTypeDescriptor.$isBuilding.withValue(true) {
            // When in debug mode, we always build the type, so we can ensure that the type is same as the one that is already registered.
            #if !DEBUG
                var identifier = FastDDS.Types.TypeIdentifierPair()
                if FastDDS.Types.getIdentifiersForName(name: .init(name), identifiers: &identifier) {
                    return DDSTypeDescriptor(identifier: identifier, name: name)
                }
            #endif

            var builder = DDSStructTypeBuilder(name: name)
            build(&builder)
            return builder.build()
        }
    }
}
