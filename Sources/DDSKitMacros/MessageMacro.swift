/**
 * MessageMacro.swift
 * DDSKitMacros
 * 
 * Created by Hunter Baker on 4/07/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

struct MessageMacro {
    private static func evaluateType(
        of node: AttributeSyntax,
        parent: some DeclSyntaxProtocol,
        context: (any MacroExpansionContext)?
    ) throws -> (
        type: StructDeclSyntax, name: String, loaningCompatible: Bool, hasDefaultConstructor: Bool, needsDDSInitialized: Bool,
        members: [(name: TokenSyntax, type: IdentifierTypeSyntax, binding: PatternBindingSyntax)]
    ) {
        guard let typeDecl = parent.as(StructDeclSyntax.self) else {
            let error = DDSKitDiagnosticMessage(
                message: "DDSMessage can only be applied to structs.",
                diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSMessage.structOnly"),
                severity: .error
            )
            context?.diagnose(
                Diagnostic(
                    node: parent,
                    message: error
                )
            )
            throw error
        }

        var isLoaningCompatible = true

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
                  variableDecl.bindingSpecifier.tokenKind == .keyword(.var) || variableDecl.bindingSpecifier.tokenKind == .keyword(.let) else {
                continue
            }

            let identifierPatterns: [IdentifierPatternSyntax] = variableDecl.bindings.map { $0 }.compactMap { binding in
                binding.pattern.as(IdentifierPatternSyntax.self)
            }

            // We don't send static variables
            if variableDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) {
                // Check if the variable is the ddsInitialized attribute
                if variableDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.public) }) {
                    let names = identifierPatterns.map { $0.identifier.text }
                    if names.contains("ddsInitialized") {
                        hasDDSInitialized = true
                        break
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
            guard !variableDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) else {
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
            guard variableDecl.bindingSpecifier.tokenKind == .keyword(.var) else {
                isLoaningCompatible = false
                continue
            }

            // Check if the variable has the DDSIgnored attribute
            for attribute in variableDecl.attributes {
                if attribute.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "DDSIgnored" {
                    isLoaningCompatible = false
                    // Don't include this member
                    continue memberLoop
                }
            }
            // Get all pattern bindings that are stored for the variable declaration
            var storedPatternBindings = patternBindings.filter { $0.0.accessorBlock == nil }

            // Check if the variable has a type annotation
            // If not, we can't use it, but we will show a diagnostic to make it clearer
            storedPatternBindings = storedPatternBindings.filter { binding in
                guard binding.0.typeAnnotation != nil else {
                    context?.diagnose(
                        Diagnostic(
                            node: binding.1,
                            message: DDSKitDiagnosticMessage(
                                message: """
                                DDSMessage: This member is ignored because it has no type annotation. \
                                To silence this warning if this is not intended to be sent, add @DDSIgnored.
                                """,
                                diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSMessage.noTypeAnnotation"),
                                severity: .warning
                            ),
                            fixIt: FixIt(
                                message: DDSKitFixItMessage(
                                    message: "Add @DDSIgnored",
                                    fixItID: MessageID(domain: "DDSKitMacros", id: "DDSMessage.noTypeAnnotation.addIgnored")
                                ),
                                changes: [
                                    .replace(
                                        oldNode: Syntax(variableDecl.attributes),
                                        newNode: Syntax({
                                            // Add the DDSIgnored attribute to the variable declaration
                                            var fixedAttributes = variableDecl.attributes
                                            fixedAttributes.append(.init(AttributeSyntax(leadingTrivia: .newline, attributeName: "DDSIgnored" as TypeSyntax)))
                                            return fixedAttributes.formatted()
                                        }())
                                    )
                                ]
                            )
                        )
                    )
                    return false
                }
                return true
            }

            sentMembers.append(contentsOf: storedPatternBindings)
        }

        if sentMembers.isEmpty {
            context?.diagnose(
                Diagnostic(
                    node: typeDecl.name,
                    message: DDSKitDiagnosticMessage(
                        message: "DDSMessage: \(typeDecl.name.text) should have at least one member that is sent.",
                        diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSMessage.noMembers"),
                        severity: .warning
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
            type: typeDecl,
            name: typeDecl.name.identifier!.name,
            loaningCompatible: isLoaningCompatible,
            hasDefaultConstructor: hasDefaultConstructor || hasImplicitDefaultConstructor,
            needsDDSInitialized: !hasDDSInitialized,
            members: sentMemberInfo
        )
    }

    internal static func getDDSInitializedFixIt(typeName: String, memberBlock: MemberBlockSyntax) -> FixIt {
        FixIt(
            message: DDSKitFixItMessage(
                message: "Add ddsInitialized",
                fixItID: MessageID(domain: "DDSKitMacros", id: "DDSMessage.missingConstructor.addDDSInitialized")
            ),
            changes: [
                .replace(
                    oldNode: Syntax(memberBlock.members),
                    newNode: Syntax({
                        var fixedMembers = memberBlock.members

                        var variableDecl = VariableDeclSyntax(
                            modifiers: [.init(name: .keyword(.public)), .init(name: .keyword(.static))],
                            bindingSpecifier: .keyword(.var),
                            bindings: [
                                PatternBindingSyntax(
                                    pattern: IdentifierPatternSyntax(identifier: "ddsInitialized"),
                                    typeAnnotation: TypeAnnotationSyntax(type: "Self" as TypeSyntax)
                                )
                            ]
                        ).formatted().as(VariableDeclSyntax.self)!

                        // Provided later, so it is not formatted into multiple lines
                        variableDecl.bindings[variableDecl.bindings.startIndex].accessorBlock = AccessorBlockSyntax(
                            leadingTrivia: .space,
                            accessors: .getter(" fatalError(\"Not implemented\") /* ToDo: Implement ddsInitialized for \(raw: typeName) */ ")
                        )

                        let member = MemberBlockItemSyntax(
                            leadingTrivia: .init(pieces: [
                                .newlines(2)
                            ] + fixedMembers.leadingTrivia.indentation(isOnNewline: true)!.pieces),
                            decl: variableDecl
                        )
                        fixedMembers.append(member)
                        return fixedMembers
                    }())
                )
            ]
        )
    }
}

extension MessageMacro: MemberMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) -> [DeclSyntax] {
        let typeDecl: StructDeclSyntax
        let typeName: String
        let hasConstructor: Bool
        let needsInitialized: Bool
        let memberInfo: [(name: TokenSyntax, type: IdentifierTypeSyntax, binding: PatternBindingSyntax)]
        do {
            (typeDecl, typeName, _, hasConstructor, needsInitialized, memberInfo) = try evaluateType(
                of: node, parent: declaration, context: context
            )
        } catch {
            // If we can't evaluate the type, just return an empty array
            return []
        }
        var name: StringLiteralExprSyntax = .init(content: typeName)
        var onlyCodable = false

        if case .argumentList(let arguments) = node.arguments {
            for argument in arguments {
                if argument.label?.text == "name" {
                    guard let value = argument.expression.as(StringLiteralExprSyntax.self) else {
                        let error = DDSKitDiagnosticMessage(
                            message: "DDSMessage: name must be a string literal.",
                            diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSMessage.nameStringLiteral"),
                            severity: .error
                        )
                        context.diagnose(Diagnostic(node: argument, message: error))
                        return []
                    }
                    name = value
                } else if argument.label?.text == "onlyCodable" {
                    guard let value = argument.expression.as(BooleanLiteralExprSyntax.self) else {
                        let error = DDSKitDiagnosticMessage(
                            message: "DDSMessage: onlyCodable must be a boolean literal.",
                            diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSMessage.onlyCodableBooleanLiteral"),
                            severity: .error
                        )
                        context.diagnose(Diagnostic(node: argument, message: error))
                        return []
                    }
                    onlyCodable = value.literal.tokenKind == .keyword(.true)
                } else {
                    let error = DDSKitDiagnosticMessage(
                        message: "DDSMessage: argument \"\(argument.label?.text ?? "")\" is not recognized.",
                        diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSMessage.unrecognizedArgument"),
                        severity: .error
                    )
                    context.diagnose(Diagnostic(node: argument, message: error))
                    return []
                }
            }
        }

        if !hasConstructor && needsInitialized {
            context.diagnose(
                Diagnostic(
                    node: typeDecl.name,
                    message: DDSKitDiagnosticMessage(
                        message: "DDSMessage: \(name) should have a default constructor or should define ddsInitialized.",
                        diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSMessage.missingConstructor"),
                        severity: .error,
                    ),
                    fixIt: getDDSInitializedFixIt(
                        typeName: typeName,
                        memberBlock: typeDecl.memberBlock
                    )
                )
            )
        }

        var outputs: [DeclSyntax] = []

        // Create ddsInitialized
        if needsInitialized {
            let ddsInitializedDecl = VariableDeclSyntax(
                modifiers: [.init(name: .keyword(.public)), .init(name: .keyword(.static))],
                bindingSpecifier: .keyword(.var),
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

        // type support is only needed if we want a DDSMessage conformance
        if !onlyCodable {
            // Create ddsTypeDescriptor
            let typeSupportDecl = VariableDeclSyntax(
                modifiers: [.init(name: .keyword(.public)), .init(name: .keyword(.static))],
                bindingSpecifier: .keyword(.var),
                bindings: [
                    PatternBindingSyntax(
                        pattern: IdentifierPatternSyntax(identifier: "ddsTypeSupport"),
                        typeAnnotation: TypeAnnotationSyntax(type: "DDSKit.DDSTypeSupport" as TypeSyntax),
                        accessorBlock: AccessorBlockSyntax(
                            accessors: .getter("""
                                .init(name: \(name), type: Self.self)
                            """)
                        )
                    )
                ]
            )
            outputs.append(.init(typeSupportDecl))
        }

        // Create ddsTypeDescriptor
        var typeDescriptorMembers: [CodeBlockItemSyntax] = []
        var calculateSizeMembers: [CodeBlockItemSyntax] = []
        var encodeMembers: [CodeBlockItemSyntax] = []
        var decodeMembers: [CodeBlockItemSyntax] = []
        var currentMemberId: UInt32 = 0
        for member in memberInfo {
            typeDescriptorMembers.append(
                "builder.addMember(name: \"\(member.name)\", memberId: \(raw: currentMemberId), type: \(raw: member.type.name.text).self)"
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
            modifiers: [.init(name: .keyword(.public)), .init(name: .keyword(.static))],
            bindingSpecifier: .keyword(.var),
            bindings: [
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(identifier: "ddsTypeDescriptor"),
                    typeAnnotation: TypeAnnotationSyntax(type: "DDSKit.DDSTypeDescriptor" as TypeSyntax),
                    accessorBlock: AccessorBlockSyntax(
                        accessors: .getter("""
                            .createStruct(name: \(name)) { builder in
                                \(CodeBlockItemListSyntax(typeDescriptorMembers))
                            }
                        """)
                    )
                )
            ]
        )
        outputs.append(.init(typeDescriptorDecl))
        let calculateSizeDecl = FunctionDeclSyntax(
            modifiers: [.init(name: .keyword(.public))],
            name: "calculateDDSSize",
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(parameters: [
                    FunctionParameterSyntax(
                        firstName: "calculator",
                        type: AttributedTypeSyntax(
                            specifiers: [.init(SimpleTypeSpecifierSyntax(specifier: .keyword(.inout)))],
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
            modifiers: [.init(name: .keyword(.public))],
            name: "ddsEncode",
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(parameters: [
                    FunctionParameterSyntax(
                        firstName: "encoder",
                        type: AttributedTypeSyntax(
                            specifiers: [.init(SimpleTypeSpecifierSyntax(specifier: .keyword(.inout)))],
                            baseType: "DDSKit.DDSEncoder" as TypeSyntax
                        )
                    )
                ]),
                effectSpecifiers: FunctionEffectSpecifiersSyntax(
                    throwsClause: ThrowsClauseSyntax(
                        throwsSpecifier: .keyword(.throws),
                        leftParen: .leftParenToken(), type: "DDSKit.DDSEncoder.EncodingError" as TypeSyntax, rightParen: .rightParenToken()
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
            modifiers: [.init(name: .keyword(.public)), .init(name: .keyword(.mutating))],
            name: "ddsDecode",
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(parameters: [
                    FunctionParameterSyntax(
                        firstName: "decoder",
                        type: AttributedTypeSyntax(
                            specifiers: [.init(SimpleTypeSpecifierSyntax(specifier: .keyword(.inout)))],
                            baseType: "DDSKit.DDSDecoder" as TypeSyntax
                        )
                    )
                ]),
                effectSpecifiers: FunctionEffectSpecifiersSyntax(
                    throwsClause: ThrowsClauseSyntax(
                        throwsSpecifier: .keyword(.throws),
                        leftParen: .leftParenToken(), type: "DDSKit.DDSDecoder.DecodingError" as TypeSyntax, rightParen: .rightParenToken()
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
    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) -> [ExtensionDeclSyntax] {
        let loaningCompatible: Bool
        let memberInfo: [(name: TokenSyntax, type: IdentifierTypeSyntax, binding: PatternBindingSyntax)]
        do {
            let info = try evaluateType(of: node, parent: declaration, context: nil)
            loaningCompatible = info.loaningCompatible
            memberInfo = info.members
        } catch {
            // If we can't evaluate the type, just return an empty array
            return []
        }

        var onlyCodable = false
        if case .argumentList(let arguments) = node.arguments {
            for argument in arguments {
                if argument.label?.text == "onlyCodable" {
                    guard let value = argument.expression.as(BooleanLiteralExprSyntax.self) else {
                        return []
                    }
                    onlyCodable = value.literal.tokenKind == .keyword(.true)
                }
            }
        }
        
        let allPrimitive = memberInfo.allSatisfy { ddsLoaningTypes.contains($0.type.name.text) }

        var extensions: [ExtensionDeclSyntax] = [try! ExtensionDeclSyntax("extension \(type): DDSCodable {}")]
        if !onlyCodable {
            extensions.append(try! ExtensionDeclSyntax("extension \(type): DDSMessage {}"))
        }
        if allPrimitive && loaningCompatible {
            extensions.append(try! ExtensionDeclSyntax("extension \(type): DDSLoaningCodable {}"))
        }
        return extensions
    }
}
