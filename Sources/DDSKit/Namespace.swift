/**
 * Namespace.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 4/04/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */

/// Represents a namespace in a DDS domain.
/// A namespace is a logical grouping of DDS entities.
/// Namespaces can be nested and can be applied after the fact.
public struct DDSNamespace: Sendable, Hashable, Codable {
    /// The components of the path.
    public private(set) var components: [String]
    /// Whether the namespace is absolute or relative.
    public private(set) var isAbsolute: Bool

    /// Creates a new namespace with the given components and absolute flag.
    /// - Parameters:
    ///   - components: The components of the namespace.
    ///   - isAbsolute: Whether the namespace is absolute or relative.
    /// - Note: The components are not normalized to remove redundant components.
    internal init(components: [String], isAbsolute: Bool) {
        self.components = components
        self.isAbsolute = isAbsolute
    }

    /// Creates a new namespace by parsing a string path.
    /// - Parameter path: The string path to parse. Forward slashes `/` are used to separate components. Standard rules for `..` and `.` apply.
    public init(path: String) {
        isAbsolute = path.hasPrefix("/")
        components = path.split(separator: "/").filter { !$0.isEmpty }.map { String($0) }

        normalize()
    }

    /// Normalizes the namespace by removing redundant components.
    /// This includes removing `..` and `.` components.
    internal mutating func normalize() {
        var normalized: [String] = []
        for component in components {
            if component == "." {
                continue
            } else if component == ".." {
                if !normalized.isEmpty {
                    normalized.removeLast()
                }
            } else if component != "." {
                normalized.append(component)
            }
        }
        components = normalized
    }
}

extension DDSNamespace {
    /// The root namespace.
    public static var root: DDSNamespace {
        DDSNamespace(components: [], isAbsolute: true)
    }

    /// The current namespace for the task.
    /// This is used to get what namespace an entity should be created in when creating a new entity.
    /// - Note: This is a task-local variable, so it is only valid for the current task.
    @TaskLocal
    public static var current: DDSNamespace = .root
}

/// Sets the namespace for anything created in the closure.
/// This stacks; it will append the namespace to the current namespace.
/// - Parameters:
///   - namespace: The namespace to set.
///   - body: The closure to execute with the new namespace.
/// - Returns: The result of the closure.
/// - Throws: An error if the closure throws.
@inlinable
public func withDDSNamespace<T, E: Error>(_ namespace: DDSNamespace, _ body: () throws(E) -> T) throws(E) -> T {
    let newNamespace = DDSNamespace.current.appending(namespace)

    var result: Result<T, E>!
    DDSNamespace.$current.withValue(newNamespace) {
        result = .init { () throws(E) in
            try body()
        }
    }

    return try result.get()
}
/// Sets the namespace for anything created in the async closure.
/// This stacks; it will append the namespace to the current namespace.
/// - Parameters:
///   - namespace: The namespace to set.
///   - body: The async closure to execute with the new namespace.
/// - Returns: The result of the closure.
/// - Throws: An error if the closure throws.
@inlinable
public func withDDSNamespace<T, E: Error>(_ namespace: DDSNamespace, _ body: () async throws(E) -> T) async throws(E) -> T {
    let newNamespace = DDSNamespace.current.appending(namespace)

    var result: Result<T, E>!
    await DDSNamespace.$current.withValue(newNamespace) {
        do throws(E) {
            result = try await .success(body())
        } catch let e {
            result = .failure(e)
        }
    }

    return try result.get()
}

extension DDSNamespace {
    /// Creates a new namespace by appending another namespace to the current namespace.
    /// - Parameter namespace: The namespace to append.
    /// - Returns: A new namespace with the namespace appended.
    public func appending(_ namespace: DDSNamespace) -> DDSNamespace {
        if namespace.isAbsolute {
            return namespace
        } else {
            var newNamespace = DDSNamespace(components: components + namespace.components, isAbsolute: isAbsolute)
            newNamespace.normalize()
            return newNamespace
        }
    }
    /// Creates a new namespace by appending another namespace to the current namespace.
    /// - Parameter namespace: The namespace to append.
    /// - Returns: A new namespace with the namespace appended.
    public func appending(relative namespace: DDSNamespace) -> DDSNamespace {
        var newNamespace = DDSNamespace(components: components + namespace.components, isAbsolute: isAbsolute)
        newNamespace.normalize()
        return newNamespace
    }
    /// Creates a new namespace by appending another path to the current namespace.
    /// - Parameter path: The path to append.
    /// - Returns: A new namespace with the path appended.
    public func appending(_ path: String) -> DDSNamespace {
        appending(DDSNamespace(path: path))
    }
    /// Creates a new namespace by appending another path to the current namespace.
    /// - Parameter path: The path to append.
    /// - Returns: A new namespace with the path appended.
    public func appending(relative path: String) -> DDSNamespace {
        appending(relative: DDSNamespace(path: path))
    }

    /// Creates a new namespace by appending another namespace to the current namespace.
    /// - Parameters:
    ///   - lhs: The namespace to append to.
    ///   - rhs: The namespace to append.
    /// - Returns: A new namespace with the namespace appended.
    public static func / (lhs: DDSNamespace, rhs: DDSNamespace) -> DDSNamespace {
        lhs.appending(rhs)
    }
    /// Creates a new namespace by appending another path to the current namespace.
    /// - Parameters:
    ///   - lhs: The namespace to append to.
    ///   - rhs: The path to append.
    /// - Returns: A new namespace with the path appended.
    public static func / (lhs: DDSNamespace, rhs: String) -> DDSNamespace {
        lhs.appending(rhs)
    }
}

extension DDSNamespace: ExpressibleByStringLiteral, LosslessStringConvertible {
    /// Creates a new namespace from a string literal path.
    /// - Parameter value: The string literal to parse.
    public init(stringLiteral value: String) {
        self.init(path: value)
    }

    /// Creates a new namespace from a string.
    /// - Parameter description: The string to parse.
    public init(_ description: String) {
        self.init(path: description)
    }

    /// The string representation of the namespace.
    public var description: String {
        if isAbsolute {
            "/" + components.joined(separator: "/")
        } else {
            components.joined(separator: "/")
        }
    }
}

extension DDSNamespace {
    /// The type of entity to generate a name for.
    public enum NameType {
        /// Generate a name for a topic.
        case topic

        /// Generate a name for an action request topic.
        case actionRequest

        /// Generate a name for an action reply topic.
        case actionReply
    }

    /// The naming convention to use for topic names.
    public enum NamingConvention {
        /// The default naming convention.
        /// This mode is very plain and just directly uses the path as the name.
        case `default`

        /// The ROS 2 naming convention.
        /// This will use the proper topic prefix for topics and will make actions use the same schema as ROS services.
        case ros2
    }

    /// Converts the namespace to a topic name for the given entity type and naming convention.
    /// - Parameters:
    ///   - type: The entity type to generate a name for.
    ///   - convention: The naming convention to use.
    /// - Returns: The topic name.
    public func getName(type: NameType, convention: NamingConvention = .default) -> String {
        switch type {
            case .topic:
                getTopicName(convention: convention)
            case .actionRequest:
                getActionTopicNames(convention: convention).request
            case .actionReply:
                getActionTopicNames(convention: convention).reply
        }
    }

    /// Converts the namespace to a topic name.
    /// - Parameter convention: The naming convention to use.
    /// - Returns: The topic name.
    internal func getTopicName(convention: NamingConvention = .default) -> String {
        switch convention {
            case .default:
                description
            case .ros2:
                if isAbsolute {
                    "rt" + description
                } else {
                    "rt/" + description
                }
        }
    }
    /// Converts the namespace to a topic name.
    /// - Parameter convention: The naming convention to use.
    /// - Returns: The topic name.
    internal func getActionTopicNames(convention: NamingConvention = .default) -> (request: String, reply: String) {
        switch convention {
            case .default:
                ((self / "request").description, (self / "reply").description)
            case .ros2:
                if isAbsolute {
                    ("rq" + description, "rp" + description)
                } else {
                    ("rq/" + description, "rp/" + description)
                }
        }
    }
}

extension DDSNamespace: DDSCodable {
    public static var ddsInitialized: DDSNamespace {.init(path: "")}

    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        .createStruct(name: "DDSKit.DDSNamespace") { builder in
            builder.addMember(name: "components", memberId: 0, type: [String].self)
            builder.addMember(name: "isAbsolute", memberId: 1, type: Bool.self)
        }
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        calculator.withStruct { calculator in
            calculator.add(member: 0, components)
            calculator.add(member: 1, isAbsolute)
        }
    }

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        try encoder.withStruct { encoder throws(DDSEncoder.EncodingError) in
            try encoder.encode(member: 0, components)
            try encoder.encode(member: 1, isAbsolute)
        }
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        try decoder.withStruct { decoder, memberId throws(DDSDecoder.DecodingError) in
            switch memberId {
                case 0:
                    try decoder.decode(&components)
                case 1:
                    try decoder.decode(&isAbsolute)
                default:
                    throw .unknownMember
            }
        }
    }
}
