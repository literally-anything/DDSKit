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
    /// Whether the type is bounded or unbounded.
    /// This is updated as members are added.
    public fileprivate(set) var isBounded: Bool = true
    /// Whether the serialization is plain or not (can be loaned).
    /// This is updated as members are added.
    public fileprivate(set) var isPlain: Bool = true
    /// All the max size calculators for each member.
    /// This is updated as members are added.
    public private(set) var maxSizeCalculators: [@Sendable (Int) -> Int] = []

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
    ///   - memberName: The name of the member.
    ///   - memberId: The id of the member.
    ///   - optional: Whether the member is optional. Defaults to `false`.
    ///   - descriptor: The descriptor of the type to add as a member.
    /// - Note: This method will throw a fatal error if the member type cannot be added.
    public mutating func addMember(name memberName: String, memberId: UInt32, optional: Bool = false, descriptor: DDSTypeDescriptor) {
        guard FastDDS.Types.addStructMember(
            info: &info, identifiers: descriptor.identifier, name: .init(memberName), id: memberId, isOptional: optional, isKey: false
        ) else {
            fatalError("Failed to add member \"\(memberName)\" to DDS type builder: \(name). This is likely either two members with the same id or a library bug.")
        }

        // A type is only bounded if all of its members are bounded and is only plain if all of its members are plain and bounded.
        isBounded = isBounded && descriptor.isBounded
        isPlain = isPlain && isBounded && descriptor.isPlain
        maxSizeCalculators.append(descriptor.calculateMaxSize)
    }

    /// Adds a member to the type being built using the given `DDSCodable` type.
    /// - Parameters:
    ///   - memberName: The name of the member.
    ///   - memberId: The id of the member.
    ///   - type: The type of the member.
    /// - Note: This method will throw a fatal error if the member type cannot be added.
    @inlinable
    public mutating func addMember<T: DDSCodable>(name memberName: String, memberId: UInt32, type: T.Type) {
        addMember(name: memberName, memberId: memberId, optional: false, descriptor: T.ddsTypeDescriptor)
    }
    /// Adds a member to the type being built using the given optional `DDSCodable` type.
    /// - Parameters:
    ///   - memberName: The name of the member.
    ///   - memberId: The id of the member.
    ///   - type: The type of the optional member.
    /// - Note: This method will throw a fatal error if the member type cannot be added.
    @inlinable
    public mutating func addMember<T: DDSCodable>(name memberName: String, memberId: UInt32, type: T?.Type) {
        addMember(name: memberName, memberId: memberId, optional: true, descriptor: T.ddsTypeDescriptor)
    }

    /// Finishes building and registering the type and returns the built descriptor.
    /// - Parameter identifiers: The identifiers for the type. This is passed by reference so that it can be modified.
    /// - Note: This method will throw a fatal error if the type cannot be built.
    internal func build(identifiers: inout FastDDS.Types.TypeIdentifierPair) {
        let ret = FastDDS.Types.finishStruct(info: info, name: .init(name), identifiers: &identifiers)
        switch ret {
            case eprosima.fastdds.dds.RETCODE_OK: break
            case eprosima.fastdds.dds.RETCODE_BAD_PARAMETER:
                fatalError("Failed to build DDS type: \(name). Another type with the same name already exists.")
            default:
                fatalError("Failed to build DDS type: \(name). Some internal error occured while building: \(ret).")
        }
    }
}

extension DDSTypeDescriptor {
    /// Creates a new struct type descriptor by building it with the given name and build closure.
    /// The closure is only called the first time the type is created. All subsequent calls will look up the type by name.
    /// - Parameters:
    ///   - name: The name of the type to build.
    ///   - isBounded: Whether the type is bounded or unbounded. Defaults to `nil`, which means is is determined based on the members.
    ///   - isPlain: Whether the serialization is plain or not (can be loaned). Defaults to `nil`, which means is is determined based on the members.
    ///   - build: The closure to build the type with.
    public static func createStruct(name: String, isBounded: Bool? = nil, isPlain: Bool? = nil, build: (inout DDSStructTypeBuilder) -> Void) -> DDSTypeDescriptor {
        // Lock the building process to avoid data races, but no need to lock if the task we are running on is already building this type.
        if !DDSTypeDescriptor.isBuilding { DDSTypeDescriptor.lock.wait() }
        defer { if !DDSTypeDescriptor.isBuilding { DDSTypeDescriptor.lock.signal() } }
        return DDSTypeDescriptor.$isBuilding.withValue(true) {
            var identifiers = FastDDS.Types.TypeIdentifierPair()

            var builder = DDSStructTypeBuilder(name: name)
            build(&builder)

            var foundExistingType = false
            #if !DEBUG
                foundExistingType = FastDDS.Types.getIdentifiersForName(name: .init(name), identifiers: &identifiers)
            #endif
            if !foundExistingType {
                builder.build(identifiers: &identifiers)
            }

            // Force isBounded and isPlain when they are passed in
            if let isBounded = isBounded {
                builder.isBounded = isBounded
            }
            if let isPlain = isPlain {
                builder.isPlain = isPlain
            }

            let maxSizeCalculators = builder.maxSizeCalculators
            return DDSTypeDescriptor(
                identifier: identifiers, name: .init(name),
                isBounded: builder.isBounded, isPlain: builder.isPlain
            ) { initialAlignment in
                var alignment = initialAlignment
                for calculator in maxSizeCalculators {
                    alignment += calculator(alignment)
                }
                return alignment - initialAlignment
            }
        }
    }
}
