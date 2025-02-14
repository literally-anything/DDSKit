/**
 * CheckedEntity.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/11/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */

/// A protocol for any FastDDS entity that can be wrapped with a `CheckedEntityWrapper`.
internal protocol DestroyableEntity {
    /// Whether the underlying entity has been destroyed.
    var destroyed: Bool { get }
}

#if DEBUG
/// A property wrapper that asserts that the wrapped entity has not been destroyed before modifying it.
/// Note: This should only be used in debug builds. It makes a bunch of extra copys and checks just for my sanity.
@propertyWrapper
internal struct CheckedEntityWrapper<Entity: DestroyableEntity> {
    /// Ensures that the wrapped entity has not been destroyed before modifying it.
    private func assertNotDestroyed() {
        assert(!wrappedValue.destroyed, "Underlying \(Entity.self) was already destroyed")
    }

    /// The wrapped entity.
    private var entity: Entity

    /// The accessor for the wrapped value. This does nothing in release builds.
    /// In debug builds, this will assert that the wrapped entity has not been destroyed before using it.
    internal var wrappedValue: Entity {
        set {
            assertNotDestroyed()
            entity = newValue
        }
        get {
            assertNotDestroyed()
            return entity
        }
    }

    /// Initializes the wrapped value with the given entity.
    /// - Parameter wrappedValue: The entity to wrap.
    internal init(wrappedValue: Entity) {
        entity = wrappedValue
    }
}
#endif
