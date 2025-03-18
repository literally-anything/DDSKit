/**
 * TypeDescriptor.swift
 * DDSCodable
 * 
 * Created by Hunter Baker on 3/16/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

/// A descriptor for a DDS type.
public struct DDSTypeDescriptor: Sendable, CustomStringConvertible {
    /// The internal xtypes identifier pair for the type.
    internal let identifier: FastDDS.Types.TypeIdentifierPair
    /// The registered name of the type.
    public let name: String

    /// Creates a new type descriptor with the given identifier and name.
    /// - Parameters:
    ///   - identifier: The internal xtypes identifier pair for the type.
    ///   - name: The registered name of the type.
    internal init(identifier: FastDDS.Types.TypeIdentifierPair, name: String) {
        self.identifier = identifier
        self.name = name
    }

    /// Creates a new type descriptor by building it with the given name and build closure.
    /// The closure is only called the first time the type is created. All subsequent calls will look up the type by name.
    /// - Parameters:
    ///   - name: The name of the type to build.
    ///   - build: The closure to build the type with.
    public init(build name: String, build: (inout DDSTypeBuilder) -> Void) {
        var identifier = FastDDS.Types.TypeIdentifierPair()
        if FastDDS.Types.getIdentifiersForName(name: .init(name), identifiers: &identifier) {
            self.identifier = identifier
            self.name = name
            return
        }

        var builder = DDSTypeBuilder(name: name)
        build(&builder)
        self = builder.build()
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

/// A builder for creating DDS types.
public class DDSTypeBuilder {
    /// The internal info for the type builder.
    internal var info = FastDDS.Types.CreateInfo()

    /// Creates a new type builder with the given name.
    /// - Parameter name: The name of the type to build. This name is only local and needs to be unique, so it's best to just make it very specific.
    /// - Note: This method will throw a fatal error if the type cannot be created.
    internal init(name: String) {
        guard FastDDS.Types.createStruct(name: .init(name), info: &info) else {
            fatalError("Failed to create DDS type builder. This is likely a library bug.")
        }
    }

    /// Adds a member to the type being built using the given descriptor.
    /// - Parameters:
    ///   - descriptor: The descriptor of the type to add as a member.
    ///   - name: The name of the member.
    ///   - memberId: The id of the member.
    ///   - optional: Whether the member is optional. Defaults to `false`.
    /// - Returns: The type builder for chaining.
    /// - Note: This method will throw a fatal error if the member type cannot be added.
    @discardableResult
    public func addMember(descriptor: DDSTypeDescriptor, name: String, memberId: UInt32, optional: Bool = false) -> Self {
        guard FastDDS.Types.addStructMember(
            info: &info, identifiers: descriptor.identifier, name: .init(name), id: memberId, isOptional: optional, isKey: false
        ) else {
            fatalError("Failed to add member to DDS type builder. This is likely either two members with the same id or a library bug.")
        }
        return self
    }

    /// Adds a member to the type being built using the given `DDSCodable` type.
    /// - Parameters:
    ///   - type: The type of the member.
    ///   - name: The name of the member.
    ///   - memberId: The id of the member.
    /// - Returns: The type builder for chaining.
    /// - Note: This method will throw a fatal error if the member type cannot be added.
    @inlinable
    @discardableResult
    public func addMember<T: DDSCodable>(type: T.Type, name: String, memberId: UInt32) -> Self {
        return addMember(descriptor: T.ddsTypeDescriptor, name: name, memberId: memberId, optional: false)
    }
    /// Adds a member to the type being built using the given optional `DDSCodable` type.
    /// - Parameters:
    ///   - type: The optional type of the member.
    ///   - name: The name of the member.
    ///   - memberId: The id of the member.
    /// - Returns: The type builder for chaining.
    /// - Note: This method will throw a fatal error if the member type cannot be added.
    @inlinable
    @discardableResult
    public func addMember<T: DDSCodable>(type: T?.Type, name: String, memberId: UInt32) -> Self {
        return addMember(descriptor: T.ddsTypeDescriptor, name: name, memberId: memberId, optional: true)
    }

    /// Finishes building and registering the type and returns the built descriptor.
    /// - Returns: The built descriptor.
    /// - Note: This method will throw a fatal error if the type cannot be built.
    internal func build() -> DDSTypeDescriptor {
        var name = std.string()
        var identifiers = FastDDS.Types.TypeIdentifierPair()
        let ret = FastDDS.Types.finishStruct(info: info, name: &name, identifiers: &identifiers)
        switch ret {
            case eprosima.fastdds.dds.RETCODE_OK: break
            case eprosima.fastdds.dds.RETCODE_BAD_PARAMETER:
                fatalError(
                    "Failed to build DDS type: \(name). Another type with the same name already exists. This name is only local, so it's best to just make it more unique."
                )
            default:
                fatalError("Failed to build DDS type. Some internal error occured while building \(name).")
        }
        return DDSTypeDescriptor(identifier: identifiers, name: .init(name))
    }
}
