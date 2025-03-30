/**
 * EnumTypeBuilder.swift
 * TypeBuilders
 * 
 * Created by Hunter Baker on 3/29/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

/// A builder for creating DDS enum types (represented as unions with struct members).
public struct DDSEnumTypeBuilder: ~Copyable {
    /// The internal info for the type builder.
    internal var info = FastDDS.Types.UnionCreateInfo()
    /// The name of the enum type.
    public let name: String

    /// Creates a new enum type builder with the given name and case count.
    /// - Parameters
    ///   - name: The name of the enum type.
    ///   - descriminator: The type descriptor of the descriminator type.
    /// - Note: This method will throw a fatal error if the type cannot be created.
    internal init(name: String, descriminator: DDSTypeDescriptor) {
        self.name = name
        guard FastDDS.Types.createUnion(name: .init(name), descriminator: descriminator.identifier, isDescriminatorKey: false, info: &info) else {
            fatalError("Failed to create DDS enum type builder: \(name). This is likely a library bug.")
        }
    }

    /// Adds a case to the enum type being built using the given descriptor.
    /// - Parameters:
    ///   - descriptor: The descriptor of the type to add as a case.
    ///   - caseName: The name of the case.
    ///   - caseId: The id of the case.
    /// - Note: This method will throw a fatal error if the case type cannot be added.
    public mutating func addCase(descriptor: DDSTypeDescriptor, name caseName: String, caseId: UInt32) {
        guard FastDDS.Types.addUnionCase(
            info: &info, identifiers: descriptor.identifier, name: .init(caseName), id: caseId
        ) else {
            fatalError("Failed to add case \"\(caseName)\" to DDS enum type builder: \(name). This is likely either two cases with the same id or a library bug.")
        }
    }

    /// Adds a case with multiple members to the enum type defined using the passed build closure.
    /// - Parameters:
    ///   - caseName: The name of the case.
    ///   - caseId: The id of the case.
    ///   - build: The closure to build the case with.
    /// - Note: This method will throw a fatal error if the case type cannot be added.
    public mutating func addCase(name caseName: String, caseId: UInt32, build: (inout DDSStructTypeBuilder) -> Void) {
        let caseDescriptor = DDSTypeDescriptor.createStruct(name: name + "." + caseName, build: build)
        guard FastDDS.Types.addUnionCase(
            info: &info, identifiers: caseDescriptor.identifier, name: .init(caseName), id: caseId
        ) else {
            fatalError("Failed to add case \"\(caseName)\" to DDS enum type builder: \(name). This is likely either two cases with the same id or a library bug.")
        }
    }

    /// Adds a case to the enum type being built using the given `DDSCodable` type.
    /// - Parameters:
    ///   - type: The type of the case.
    ///   - caseName: The name of the case.
    ///   - caseId: The id of the case.
    /// - Note: This method will throw a fatal error if the case type cannot be added.
    @inlinable
    public mutating func addCase<T: DDSCodable>(type: T.Type, name caseName: String, caseId: UInt32) {
        addCase(descriptor: T.ddsTypeDescriptor, name: caseName, caseId: caseId)
    }

    /// Builds and registers the enum type.
    /// - Returns: The identifier pair for the enum type.
    /// - Note: This method will throw a fatal error if the type cannot be created.
    internal func build() -> DDSTypeDescriptor {
        var identifier = FastDDS.Types.TypeIdentifierPair()

        let ret = FastDDS.Types.finishUnion(info: info, name: .init(name), identifiers: &identifier)
        switch ret {
            case eprosima.fastdds.dds.RETCODE_OK: break
            case eprosima.fastdds.dds.RETCODE_BAD_PARAMETER:
                fatalError("Failed to build DDS type: \(name). Another type with the same name already exists.")
            default:
                fatalError("Failed to build DDS type: \(name). Some internal error occured while building: \(ret).")
        }

        return DDSTypeDescriptor(identifier: identifier, name: name)
    }
}

extension DDSTypeDescriptor {
    /// Creates a new enum (union) type descriptor by building it with the given name and build closure.
    /// The closure is only called the first time the type is created. All subsequent calls will look up the type by name.
    /// - Parameters:
    ///   - name: The name of the type to build.
    ///   - descriminator: The type descriptor of the descriminator type.
    ///   - build: The closure to build the type with.
    public static func createEnum(name: String, descriminator: DDSTypeDescriptor, build: (inout DDSEnumTypeBuilder) -> Void) -> DDSTypeDescriptor {
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

            var builder = DDSEnumTypeBuilder(name: name, descriminator: descriminator)
            build(&builder)
            return builder.build()
        }
    }
}
