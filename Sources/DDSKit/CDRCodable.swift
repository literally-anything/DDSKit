/**
 * CDRCodable.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 1/23/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
public import _CFastDDS

public protocol CDRCodable: Codable {
    static func buildXTypesDescriptor() -> TypeIdentifierPair
}

extension UInt32: CDRCodable {
    public static func buildXTypesDescriptor() -> TypeIdentifierPair {
        var identifiers = XTypes.initIdentifierPair()
        if !XTypes.getIdentifiers(name: "_uint32_t", identifiers: &identifiers) {
            fatalError("Failed to get XType identifiers for primitive type: UInt32")
        }
        return identifiers
    }
}
