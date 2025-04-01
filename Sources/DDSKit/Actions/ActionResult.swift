/**
 * Result.swift
 * Actions
 * 
 * Created by Hunter Baker on 4/01/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */

/// Just a protocol for Result to conform to so that we can make extensions based on a generic Result.
/// This is used in ActionServer and ActionClient to add special handling for the result type.
public protocol DDSActionResult: DDSCodable, DDSMessage {
    associatedtype Success: DDSCodable
    associatedtype Failure: DDSCodable & Error

    init(catching body: () throws(Failure) -> Success)
    consuming func get() throws(Failure) -> Success
}

extension Result: DDSActionResult where Success: DDSCodable, Failure: DDSCodable {}
