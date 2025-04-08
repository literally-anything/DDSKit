/**
 * IgnoredMacro.swift
 * DDSKitMacros
 * 
 * Created by Hunter Baker on 4/07/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
public import SwiftSyntax
public import SwiftSyntaxMacros

/// A macro that ignores the declaration it is applied to.
/// This doesn't actually do anything, it's just used as a marker of ignored members.
public struct IgnoredMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}
