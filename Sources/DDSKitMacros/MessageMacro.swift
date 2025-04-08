/**
 * MessageMacro.swift
 * DDSKitMacros
 * 
 * Created by Hunter Baker on 4/07/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
public import SwiftSyntax
public import SwiftSyntaxMacros
internal import SwiftDiagnostics

public struct MessageMacro {
    internal static func evaluateType(
        of node: AttributeSyntax,
        parent: some DeclSyntaxProtocol,
        context: some MacroExpansionContext
    ) throws -> (hasDefaultConstructor: Bool, needsDDSInitialized: Bool, members: [(name: TokenSyntax, type: IdentifierTypeSyntax, binding: PatternBindingSyntax)]) {
        guard let typeDecl = parent.as(StructDeclSyntax.self) else {
            let error = DDSKitDiagnosticMessage(
                message: "DDSMessage can only be applied to structs.",
                diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSMessage.structOnly"),
                severity: .error
            )
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: error
                )
            )
            throw error
        }

        // Check if the type has a default constructor and a .ddsInitialized static member
        var hasDefaultConstructor = false
        var hasDDSInitialized = false
        for member in typeDecl.memberBlock.members {
            if let initializer = member.decl.as(InitializerDeclSyntax.self) {
                // Check if the initializer is a default constructor
                if initializer.signature.parameterClause.parameters.isEmpty {
                    hasDefaultConstructor = true
                }
            }

            // Find all variable and constant declarations
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self),
                  variableDecl.bindingSpecifier.text == "var" || variableDecl.bindingSpecifier.text == "let" else {
                continue
            }

            let identifierPatterns: [IdentifierPatternSyntax] = variableDecl.bindings.map { $0 }.compactMap { binding in
                binding.pattern.as(IdentifierPatternSyntax.self)
            }

            // We don't send static variables
            if variableDecl.modifiers.contains(where: { $0.name.text == "static" }) {
                // Check if the variable is the ddsInitialized attribute
                if variableDecl.modifiers.contains(where: { $0.name.text == "public" }) {
                    let names = identifierPatterns.map { $0.identifier.text }
                    if names.contains("ddsInitialized") {
                        hasDDSInitialized = true
                    }
                }
            }
        }

        // Find all member variables that are not ignored
        // Also check if all stored variables have initializers (will a default constructor be created?)
        var hasImplicitDefaultConstructor = true
        var sentMembers: [(PatternBindingSyntax, IdentifierPatternSyntax)] = []
        memberLoop: for member in typeDecl.memberBlock.members {
            // Find all variable declarations
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }

            // We don't send static variables
            guard !variableDecl.modifiers.contains(where: { $0.name.text == "static" }) else {
                continue
            }

            let patternBindings: [(PatternBindingSyntax, IdentifierPatternSyntax)] = variableDecl.bindings.map { $0 }.compactMap { binding in
                let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self)
                if let identifierPattern {
                    return (binding as PatternBindingSyntax, identifierPattern)
                }
                return nil
            }

            // Check if every pattern binding has an initializer
            if !(hasImplicitDefaultConstructor && patternBindings.allSatisfy { $0.0.initializer != nil }) {
                hasImplicitDefaultConstructor = false
            }

            // We only care about variables, not constants
            guard variableDecl.bindingSpecifier.text == "var" else {
                continue
            }

            // Check if the variable has the DDSIgnored attribute
            for attribute in variableDecl.attributes {
                if attribute.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "DDSIgnored" {
                    // Don't include this member
                    continue memberLoop
                }
            }
            // Get all pattern bindings that are stored for the variable declaration
            let storedPatternBindings = patternBindings.filter { $0.0.accessorBlock == nil && $0.0.typeAnnotation != nil }

            sentMembers.append(contentsOf: storedPatternBindings)
        }

        if sentMembers.isEmpty {
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: DDSKitDiagnosticMessage(
                        message: "DDSMessage: \(typeDecl.name) should have at least one member that is sent.",
                        diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSMessage.noMembers"),
                        severity: .remark
                    )
                )
            )
        }

        // Extract the name and type of each member
        let sentMemberInfo: [(name: TokenSyntax, type: IdentifierTypeSyntax, binding: PatternBindingSyntax)] = sentMembers.map { member in
            (
                name: member.1.identifier,
                type: member.0.typeAnnotation!.type.as(IdentifierTypeSyntax.self)!,
                binding: member.0
            )
        }

        return (
            hasDefaultConstructor: hasDefaultConstructor || hasImplicitDefaultConstructor,
            needsDDSInitialized: !hasDDSInitialized,
            members: sentMemberInfo
        )
    }
}

extension MessageMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let (hasConstructor, needsInitialized, memberInfo) =  try evaluateType(of: node, parent: declaration, context: context)

        if !hasConstructor && needsInitialized {
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: DDSKitDiagnosticMessage(
                        message: "DDSMessage: \(declaration.as(StructDeclSyntax.self)!.name) should have a default constructor or should define ddsInitialized.",
                        diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSMessage.missingConstructor"),
                        severity: .error
                    )
                )
            )
        }

        return []
    }
}

extension MessageMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let (_, _, memberInfo) =  try evaluateType(of: node, parent: declaration, context: context)

        let primitiveTypes = [
            "Bool",
            "Int8", "UInt8",
            "Int16", "UInt16",
            "Int32", "UInt32",
            "Int64", "UInt64",
            "Float", "Double",
            "Float16"
        ]
        let allPrimitive = memberInfo.allSatisfy { primitiveTypes.contains($0.type.name.text) }

        var extensions: [ExtensionDeclSyntax] = [try ExtensionDeclSyntax("extension \(type): DDSCodable, DDSMessage {}")]
        if allPrimitive {
            extensions.append(try ExtensionDeclSyntax("extension \(type): DDSLoaningCodable {}"))
        }
        return extensions
    }
}
