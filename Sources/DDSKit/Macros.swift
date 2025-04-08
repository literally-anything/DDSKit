/**
 * Macros.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 4/07/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */

@attached(peer)
public macro DDSIgnored() = #externalMacro(module: "DDSKitMacros", type: "IgnoredMacro")

@attached(
    member,
    names: named(ddsInitialized), named(ddsTypeSupport), named(ddsTypeDescriptor),
           named(calculateDDSSize), named(ddsEncode), named(ddsDecode)
)
@attached(extension, conformances: DDSCodable, DDSLoaningCodable, DDSMessage)
public macro DDSMessage() = #externalMacro(module: "DDSKitMacros", type: "MessageMacro")
