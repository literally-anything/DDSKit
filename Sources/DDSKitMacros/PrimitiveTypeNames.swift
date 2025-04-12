/**
 * PrimitiveTypeNames.swift
 * DDSKitMacros
 * 
 * Created by Hunter Baker on 4/12/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */

/// A list of primitive types that are able to be loaned by the DDS.
let ddsLoaningTypes: [String] = [
    "Bool",
    "Int", "UInt",
    "Int8", "UInt8",
    "Int16", "UInt16",
    "Int32", "UInt32",
    "Int64", "UInt64",
    "Float", "Double",
    "Float16", "Float80"
]
/// A list of primitive types that are known by the DDS.
/// These do not need to be loanable.
var ddsPrimitiveTypes: [String] {
    ddsLoaningTypes + [
        "String"
    ]
}
