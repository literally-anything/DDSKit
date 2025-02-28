/**
 * EntitiyIdentifier.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/26/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

/// An identifier for a DDS entity.
/// This directly maps to the fastdds GUID_t.
public struct DDSEntityIdentifier: Sendable {
    /// The underlying fastdds GUID.
    internal var guid: FastDDS.GUID

    /// The prefix of the entity identifier.
    public var `prefix`: Prefix {
        get {
            Prefix(guidPrefix: guid.guidPrefix)
        }
        set {
            guid.guidPrefix = newValue.guidPrefix
        }
    }
    /// The entity id of the entity identifier.
    public var entity: EntityId {
        get {
            EntityId(entityId: guid.entityId)
        }
        set {
            guid.entityId = newValue.entityId
        }
    }

    /// Creates a new entity identifier from a prefix and entity id.
    /// - Parameters:
    ///   - guidPrefix: The prefix of the entity identifier.
    ///   - entityId: The entity id of the entity identifier.
    public init(prefix guidPrefix: Prefix, entityId: EntityId) {
        guid = FastDDS.GUID(guidPrefix.guidPrefix, entityId.entityId)
    }
    /// Creates a new entity identifier from a raw prefix and entity id.
    /// - Parameters:
    ///   - guidPrefix: The raw fastdds GUIDPrefix.
    ///   - entityId: The raw fastdds EntityID.
    internal init(guidPrefix: FastDDS.GUIDPrefix, entityId: FastDDS.EntityID) {
        guid = FastDDS.GUID(guidPrefix, entityId)
    }
    /// Creates a new entity identifier from a fastdds GUID.
    /// - Parameter guid: The raw fastdds GUID.
    internal init(guid: FastDDS.GUID) {
        self.guid = guid
    }

    /// Whether the entity identifier is from an entity on this host.
    public var isThisHost: Bool {
        guid.is_from_this_host()
    }
    /// Whether the entity identifier is from an entity in this process.
    public var isThisProcess: Bool {
        guid.is_from_this_process()
    }

    /// Check if the entity identifier is from the same host as another entity identifier.
    /// - Parameter other: The other entity identifier.
    /// - Returns: Whether the entity identifiers are from the same host.
    public func isSameHost(as other: DDSEntityIdentifier) -> Bool {
        guid.is_on_same_host_as(other.guid)
    }
    /// Check if the entity identifier is from the same process as another entity identifier.
    /// - Parameter other: The other entity identifier.
    /// - Returns: Whether the entity identifiers are from the same process.
    public func isSameProcess(as other: DDSEntityIdentifier) -> Bool {
        guid.is_on_same_process_as(other.guid)
    }
}

extension DDSEntityIdentifier: Hashable {
    public static func == (lhs: DDSEntityIdentifier, rhs: DDSEntityIdentifier) -> Bool {
        lhs.guid == rhs.guid
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(prefix)
    }
}

extension DDSEntityIdentifier {
    /// A prefix for a DDS entity identifier.
    /// This directly maps to the fastdds GuidPrefix_t.
    /// This is what determines whether itra-process or data-sharing delivery is possible.
    public struct Prefix: Sendable, Hashable, ExpressibleByArrayLiteral {
        /// The underlying fastdds GUIDPrefix.
        internal var guidPrefix: FastDDS.GUIDPrefix

        /// The [UInt8] representation of the prefix.
        public var value: [UInt8] {
            get {
                withUnsafePointer(to: guidPrefix.value.0) { guidPrefixPtr in
                    Array(
                        UnsafeBufferPointer(start: guidPrefixPtr, count: Int(FastDDS.GUIDPrefix_size))
                    )
                }
            }
            set {
                precondition(newValue.count == Int(FastDDS.GUIDPrefix_size), "Prefix.value must be \(FastDDS.GUIDPrefix_size) bytes")
                newValue.withUnsafeBufferPointer { newValueBuffer in
                    withUnsafeMutablePointer(to: &guidPrefix.value.0) { guidPrefixPtr in
                        let guidPrefixBuffer = UnsafeMutableBufferPointer(start: guidPrefixPtr, count: Int(FastDDS.GUIDPrefix_size))
                        for (index, value) in newValueBuffer.enumerated() {
                            guidPrefixBuffer[index] = value
                        }
                    }
                }
            }
        }

        /// Creates a new prefix from an array of UInt8s.
        /// - Parameter elements: An array of UInt8s.
        public init(arrayLiteral elements: UInt8...) {
            guidPrefix = FastDDS.GUIDPrefix()
            value = elements
        }
        /// Creates a new prefix from a fastdds GUIDPrefix.
        /// - Parameter guidPrefix: The raw fastdds GUIDPrefix.
        internal init(guidPrefix: FastDDS.GUIDPrefix) {
            self.guidPrefix = guidPrefix
        }

        /// Whether the prefix is from an entity on this host.
        public var isThisHost: Bool {
            guidPrefix.is_from_this_host()
        }
        /// Whether the prefix is from an entity in this process.
        public var isThisProcess: Bool {
            guidPrefix.is_from_this_process()
        }

        /// Check if the prefix is from the same host as another prefix.
        /// - Parameter other: The other prefix.
        /// - Returns: Whether the prefixes are from the same host.
        public func isSameHost(as other: Prefix) -> Bool {
            guidPrefix.is_on_same_host_as(other.guidPrefix)
        }
        /// Check if the prefix is from the same process as another prefix.
        /// - Parameter other: The other prefix.
        /// - Returns: Whether the prefixes are from the same process.
        public func isSameProcess(as other: Prefix) -> Bool {
            guidPrefix.is_on_same_process_as(other.guidPrefix)
        }

        public static func == (lhs: Prefix, rhs: Prefix) -> Bool {
            lhs.guidPrefix == rhs.guidPrefix
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(value)
        }
    }
}

extension DDSEntityIdentifier {
    /// The entity id part of an entity identifier.
    public struct EntityId: Sendable, Hashable, ExpressibleByArrayLiteral, ExpressibleByIntegerLiteral {
        /// The underlying fastdds EntityID.
        internal var entityId: FastDDS.EntityID

        /// The UInt32 representation of the entity id.
        public var uint32: UInt32 {
            get {
                entityId.to_uint32()
            }
            set {
                entityId = FastDDS.EntityID(newValue)
            }
        }
        /// The [UInt8] representation of the entity id.
        public var value: [UInt8] {
            get {
                withUnsafePointer(to: entityId.value.0) { entityIdPtr in
                    Array(
                        UnsafeBufferPointer(start: entityIdPtr, count: Int(FastDDS.EntityID_size))
                    )
                }
            }
            set {
                precondition(newValue.count == Int(FastDDS.EntityID_size), "EntityId.value must be \(FastDDS.EntityID_size) bytes")
                newValue.withUnsafeBufferPointer { newValueBuffer in
                    withUnsafeMutablePointer(to: &entityId.value.0) { entityIdPtr in
                        let entityIdBuffer = UnsafeMutableBufferPointer(start: entityIdPtr, count: Int(FastDDS.EntityID_size))
                        for (index, value) in newValueBuffer.enumerated() {
                            entityIdBuffer[index] = value
                        }
                    }
                }
            }
        }

        /// Creates a new entity id from a UInt32 single entity id.
        /// - Parameter value: A single UInt32 entity id.
        public init(integerLiteral value: UInt32) {
            entityId = FastDDS.EntityID(value)
        }
        /// Creates a new entity id from an array of UInt8s.
        /// - Parameter elements: An array of UInt8s.
        public init(arrayLiteral elements: UInt8...) {
            entityId = FastDDS.EntityID()
            value = elements
        }
        /// Creates a new entity id from a fastdds EntityID.
        /// - Parameter entityId: The raw fastdds EntityID.
        internal init(entityId: FastDDS.EntityID) {
            self.entityId = entityId
        }

        public static func == (lhs: EntityId, rhs: EntityId) -> Bool {
            lhs.entityId == rhs.entityId
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(value)
        }
    }
}

extension Optional where Wrapped == DDSEntityIdentifier {
    /// The fastdds GUID representation of the entity identifier.
    /// If the entity identifier is nil, this will be an unknown() GUID.
    internal var guid: FastDDS.GUID {
        switch (self) {
            case .none:
                .init()
            case .some(let value):
                value.guid
        }
    }
}
