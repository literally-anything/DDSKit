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
    ) throws -> (
        name: String, hasDefaultConstructor: Bool, needsDDSInitialized: Bool,
        members: [(name: TokenSyntax, type: IdentifierTypeSyntax, binding: PatternBindingSyntax)]
    ) {
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
        var hasOtherConstructor = false
        var hasDefaultConstructor = false
        var hasDDSInitialized = false
        for member in typeDecl.memberBlock.members {
            if let initializer = member.decl.as(InitializerDeclSyntax.self) {
                // Check if the initializer is a default constructor
                if initializer.signature.parameterClause.parameters.isEmpty {
                    hasDefaultConstructor = true
                } else {
                    hasOtherConstructor = true
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
        var hasImplicitDefaultConstructor = !hasOtherConstructor // If there there is another constructor, the implicit default constructor will not be created
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
            name: typeDecl.name.identifier!.name,
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
        let (foundName, hasConstructor, needsInitialized, memberInfo) =  try evaluateType(
            of: node, parent: declaration, context: context
        )
        let name = foundName // There should be a name: argument in the macro call that will override this

        if !hasConstructor && needsInitialized {
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: DDSKitDiagnosticMessage(
                        message: "DDSMessage: \(name) should have a default constructor or should define ddsInitialized.",
                        diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSMessage.missingConstructor"),
                        severity: .error
                    )
                )
            )
        }

        var outputs: [DeclSyntax] = []

        // Create ddsInitialized
        if needsInitialized {
            let ddsInitializedDecl = VariableDeclSyntax(
                modifiers: [.init(name: "public"), .init(name: "static")],
                bindingSpecifier: "var",
                bindings: [
                    PatternBindingSyntax(
                        pattern: IdentifierPatternSyntax(identifier: "ddsInitialized"),
                        typeAnnotation: TypeAnnotationSyntax(type: "Self" as TypeSyntax),
                        accessorBlock: AccessorBlockSyntax(
                            accessors: .getter("""
                                .init()
                            """)
                        )
                    )
                ]
            )
            outputs.append(.init(ddsInitializedDecl))
        }

        // Create ddsTypeDescriptor
        let typeSupportDecl = VariableDeclSyntax(
            modifiers: [.init(name: "public"), .init(name: "static")],
            bindingSpecifier: "var",
            bindings: [
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(identifier: "ddsTypeSupport"),
                    typeAnnotation: TypeAnnotationSyntax(type: "DDSKit.DDSTypeSupport" as TypeSyntax),
                    accessorBlock: AccessorBlockSyntax(
                        accessors: .getter("""
                            .init(name: \"\(raw: name)\", type: Self.self)
                        """)
                    )
                )
            ]
        )
        outputs.append(.init(typeSupportDecl))

        // Create ddsTypeDescriptor
        var typeDescriptorMembers: [CodeBlockItemSyntax] = []
        var calculateSizeMembers: [CodeBlockItemSyntax] = []
        var encodeMembers: [CodeBlockItemSyntax] = []
        var decodeMembers: [CodeBlockItemSyntax] = []
        var currentMemberId: UInt32 = 0
        for member in memberInfo {
            typeDescriptorMembers.append(
                "builder.addMember(name: \"\(member.name)\", memberId: \(raw: currentMemberId), type: (\(member.type.name).self))"
            )
            calculateSizeMembers.append(
                "calculator.add(member: \(raw: currentMemberId), \(member.name))"
            )
            encodeMembers.append(
                "try encoder.encode(member: \(raw: currentMemberId), \(member.name))"
            )
            decodeMembers.append(
                """
                case \(raw: currentMemberId):
                    try decoder.decode(&\(member.name))
                """
            )
            currentMemberId += 1
        }
        let typeDescriptorDecl = VariableDeclSyntax(
            modifiers: [.init(name: "public"), .init(name: "static")],
            bindingSpecifier: "var",
            bindings: [
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(identifier: "ddsTypeDescriptor"),
                    typeAnnotation: TypeAnnotationSyntax(type: "DDSKit.DDSTypeDescriptor" as TypeSyntax),
                    accessorBlock: AccessorBlockSyntax(
                        accessors: .getter("""
                            .createStruct(name: \"\(raw: name)\") { builder in
                                \(CodeBlockItemListSyntax(typeDescriptorMembers))
                            }
                        """)
                    )
                )
            ]
        )
        outputs.append(.init(typeDescriptorDecl))
        let calculateSizeDecl = FunctionDeclSyntax(
            modifiers: [.init(name: "public")],
            name: "calculateDDSSize",
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(parameters: [
                    FunctionParameterSyntax(
                        firstName: "calculator",
                        type: AttributedTypeSyntax(
                            specifiers: [.init(SimpleTypeSpecifierSyntax(specifier: "inout"))],
                            baseType: "DDSKit.DDSSizeCalculator" as TypeSyntax
                        )
                    )
                ])
            ),
            body: CodeBlockSyntax(statements: """
                calculator.withStruct { calculator in
                    \(CodeBlockItemListSyntax(calculateSizeMembers))
                }
            """)
        )
        outputs.append(.init(calculateSizeDecl))
        let encodeDecl = FunctionDeclSyntax(
            modifiers: [.init(name: "public")],
            name: "ddsEncode",
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(parameters: [
                    FunctionParameterSyntax(
                        firstName: "encoder",
                        type: AttributedTypeSyntax(
                            specifiers: [.init(SimpleTypeSpecifierSyntax(specifier: "inout"))],
                            baseType: "DDSKit.DDSEncoder" as TypeSyntax
                        )
                    )
                ]),
                effectSpecifiers: FunctionEffectSpecifiersSyntax(
                    throwsClause: ThrowsClauseSyntax(
                        throwsSpecifier: "throws", leftParen: .leftParenToken(), type: "DDSKit.DDSEncoder.EncodingError" as TypeSyntax, rightParen: .rightParenToken()
                    )
                )
            ),
            body: CodeBlockSyntax(statements: """
                try encoder.withStruct { encoder throws(DDSKit.DDSEncoder.EncodingError) in
                    \(CodeBlockItemListSyntax(encodeMembers))
                }
            """)
        )
        outputs.append(.init(encodeDecl))
        let decodeDecl = FunctionDeclSyntax(
            modifiers: [.init(name: "public"), .init(name: "mutating")],
            name: "ddsDecode",
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(parameters: [
                    FunctionParameterSyntax(
                        firstName: "decoder",
                        type: AttributedTypeSyntax(
                            specifiers: [.init(SimpleTypeSpecifierSyntax(specifier: "inout"))],
                            baseType: "DDSKit.DDSDecoder" as TypeSyntax
                        )
                    )
                ]),
                effectSpecifiers: FunctionEffectSpecifiersSyntax(
                    throwsClause: ThrowsClauseSyntax(
                        throwsSpecifier: "throws", leftParen: .leftParenToken(), type: "DDSKit.DDSDecoder.DecodingError" as TypeSyntax, rightParen: .rightParenToken()
                    )
                )
            ),
            body: CodeBlockSyntax(statements: """
                try decoder.withStruct { decoder, member throws(DDSKit.DDSDecoder.DecodingError) in
                    switch member {
                        \(CodeBlockItemListSyntax(decodeMembers))
                        default:
                            throw .unknownMember
                    }
                }
            """)
        )
        outputs.append(.init(decodeDecl))

        return outputs
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
        let (_, _, _, memberInfo) =  try evaluateType(of: node, parent: declaration, context: context)

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
