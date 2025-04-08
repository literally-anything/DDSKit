/**
 * DDSKitMacros.swift
 * DDSKitMacros
 * 
 * Created by Hunter Baker on 4/07/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#if canImport(SwiftCompilerPlugin)

internal import SwiftCompilerPlugin
internal import SwiftSyntaxMacros

@main
struct DDSKitMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        IgnoredMacro.self,
        MessageMacro.self,
        // DDSEnumMacro.self
    ]
}

#endif
