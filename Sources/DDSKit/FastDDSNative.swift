/**
 * FastDDSNative.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 3/01/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

@_spi(DDSKitNative)
extension DDSParticipant {
    /// The native FastDDS DomainParticipant.
    /// This is only used when DDSKit doesn't have a function that you need and it is very specific.
    /// Most of the time, just make a Pull Request to add the functionality you need.
    /// - Warning: Using this can cause memory leaks and undefined behavior if not used correctly.
    public var nativeParticipant: OpaquePointer {
        OpaquePointer(raw.native)
    }

    /// The native FastDDS Publisher.
    /// This is only used when DDSKit doesn't have a function that you need and it is very specific.
    /// Most of the time, just make a Pull Request to add the functionality you need.
    /// - Warning: Using this can cause memory leaks and undefined behavior if not used correctly.
    public var nativePublisher: OpaquePointer {
        OpaquePointer(rawPublisher.native)
    }

    /// The native FastDDS Subscriber.
    /// This is only used when DDSKit doesn't have a function that you need and it is very specific.
    /// Most of the time, just make a Pull Request to add the functionality you need.
    /// - Warning: Using this can cause memory leaks and undefined behavior if not used correctly.
    public var nativeSubscriber: OpaquePointer {
        OpaquePointer(rawSubscriber.native)
    }
}

@_spi(DDSKitNative)
extension DDSTopic {
    /// The native FastDDS Topic.
    /// This is only used when DDSKit doesn't have a function that you need and it is very specific.
    /// Most of the time, just make a Pull Request to add the functionality you need.
    /// - Warning: Using this can cause memory leaks and undefined behavior if not used correctly.
    public var nativeTopic: OpaquePointer {
        OpaquePointer(raw.native)
    }
}

@_spi(DDSKitNative)
extension DDSPublisher {
    /// The native FastDDS DataWriter.
    /// This is only used when DDSKit doesn't have a function that you need and it is very specific.
    /// Most of the time, just make a Pull Request to add the functionality you need.
    /// - Warning: Using this can cause memory leaks and undefined behavior if not used correctly.
    public var nativeDataWriter: OpaquePointer {
        OpaquePointer(raw.native)
    }
}

@_spi(DDSKitNative)
extension DDSSubscriber {
    /// The native FastDDS DataReader.
    /// This is only used when DDSKit doesn't have a function that you need and it is very specific.
    /// Most of the time, just make a Pull Request to add the functionality you need.
    /// - Warning: Using this can cause memory leaks and undefined behavior if not used correctly.
    public var nativeDataReader: OpaquePointer {
        OpaquePointer(raw.native)
    }
}
