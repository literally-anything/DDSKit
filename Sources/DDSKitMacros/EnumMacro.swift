/**
 * EnumMacro.swift
 * DDSKitMacros
 * 
 * Created by Hunter Baker on 4/08/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

struct EnumMacro {
    private static func evaluateType(
        of node: AttributeSyntax,
        parent: some DeclSyntaxProtocol,
        context: (any MacroExpansionContext)?
    ) throws -> (
        type: EnumDeclSyntax, name: String,
        rawValue: IdentifierTypeSyntax?, hasDefaultConstructor: Bool, needsDDSInitialized: Bool,
        cases: [(name: TokenSyntax, parameters: EnumCaseParameterListSyntax?)]
    ) {
        guard let typeDecl = parent.as(EnumDeclSyntax.self) else {
            let error = DDSKitDiagnosticMessage(
                message: "DDSEnum can only be applied to enums.",
                diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSEnum.enumOnly"),
                severity: .error
            )
            context?.diagnose(
                Diagnostic(
                    node: node,
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

        // Check if the enum has a raw value that is a primitive type
        // If so, we can skip the rest of the checks
        let rawValue = typeDecl.inheritanceClause?.inheritedTypes.first?.type.as(IdentifierTypeSyntax.self)
        if let rawValue, ddsPrimitiveTypes.contains(rawValue.name.text) {
            return (
                type: typeDecl,
                name: typeDecl.name.text,
                rawValue: rawValue,
                hasDefaultConstructor: hasDefaultConstructor,
                needsDDSInitialized: !hasDDSInitialized,
                cases: []
            )
        }

        // Find all cases and check if they have a raw value
        var hasRawValue = false
        var hasParameters = false
        var cases: [(TokenSyntax, EnumCaseParameterListSyntax?)] = []
        memberLoop: for member in typeDecl.memberBlock.members {
            // Find all case declarations
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
                continue
            }

            cases.append(contentsOf: caseDecl.elements.map { element in
                if element.rawValue?.value != nil {
                    hasRawValue = true
                }
                if element.parameterClause?.parameters.count ?? 0 > 0 {
                    hasParameters = true
                }
                return (element.name, element.parameterClause?.parameters)
            })
        }

        if !hasRawValue && !hasParameters {
            var suggestedRawValue: TypeSyntax = "UInt8"
            if cases.count > UInt8.max { suggestedRawValue = "UInt16" }
            if cases.count > UInt16.max { suggestedRawValue = "UInt32" }
            if cases.count > UInt32.max { suggestedRawValue = "UInt64" }

            let error = DDSKitDiagnosticMessage(
                message: "DDSEnum: A type should either have a raw value or have cases with parameters. Fix this by adding a RawValue to the enum.",
                diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSEnum.noRawValue"),
                severity: .error
            )
            let fixit = FixIt(
                message: DDSKitFixItMessage(
                    message: "Use \(suggestedRawValue) as the RawValue",
                    fixItID: MessageID(domain: "DDSKitMacros", id: "DDSEnum.noRawValue.addOptimal")
                ),
                changes: [
                    .replace(
                        oldNode: Syntax(typeDecl),
                        newNode: Syntax({
                            var fixedDecl = typeDecl

                            if fixedDecl.inheritanceClause == nil {
                                fixedDecl.inheritanceClause = InheritanceClauseSyntax(
                                    inheritedTypes: [
                                        InheritedTypeSyntax(type: suggestedRawValue)
                                    ]
                                )
                            } else {
                                fixedDecl.inheritanceClause!.inheritedTypes.insert(
                                    InheritedTypeSyntax(
                                        type: suggestedRawValue,
                                        trailingComma: fixedDecl.inheritanceClause!.inheritedTypes.count > 0 ? .commaToken() : nil
                                    ),
                                    at: fixedDecl.inheritanceClause!.inheritedTypes.startIndex
                                )
                            }
                            fixedDecl.inheritanceClause = fixedDecl.inheritanceClause!.formatted().as(InheritanceClauseSyntax.self)!

                            return fixedDecl
                        }())
                    )
                ]
            )
            context?.diagnose(
                Diagnostic(
                    node: typeDecl.name,
                    message: error,
                    highlights: [
                        Syntax(node),
                        Syntax(typeDecl.name),
                    ],
                    fixIt: fixit
                )
            )
            throw error
        }

        if cases.isEmpty {
            context?.diagnose(
                Diagnostic(
                    node: node,
                    message: DDSKitDiagnosticMessage(
                        message: "DDSEnum: \(typeDecl.name) should have at least one case.",
                        diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSEnum.noCases"),
                        severity: .warning
                    )
                )
            )
        }

        return (
            type: typeDecl,
            name: typeDecl.name.identifier!.name,
            rawValue: hasRawValue ? rawValue : nil,
            hasDefaultConstructor: hasDefaultConstructor,
            needsDDSInitialized: !hasDDSInitialized,
            cases: cases
        )
    }
}

extension EnumMacro: MemberMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) -> [DeclSyntax] {
        let typeDecl: EnumDeclSyntax
        let typeName: String
        let rawValue: IdentifierTypeSyntax?
        let hasConstructor: Bool
        let needsInitialized: Bool
        // let cases: [(name: TokenSyntax, parameters: EnumCaseParameterListSyntax?)]
        do {
            (typeDecl, typeName, rawValue, hasConstructor, needsInitialized, _) = try evaluateType(
                of: node, parent: declaration, context: context
            )
        } catch {
            return []
        }
        var name: StringLiteralExprSyntax = .init(content: typeName)

        if case .argumentList(let arguments) = node.arguments {
            for argument in arguments {
                if argument.label?.text == "name" {
                    guard let value = argument.expression.as(StringLiteralExprSyntax.self) else {
                        let error = DDSKitDiagnosticMessage(
                            message: "DDSMessage: name must be a string literal.",
                            diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSMessage.nameStringLiteral"),
                            severity: .error
                        )
                        context.diagnose(Diagnostic(node: node, message: error))
                        return []
                    }
                    name = value
                } else {
                    let error = DDSKitDiagnosticMessage(
                        message: "DDSMessage: argument \"\(argument.label?.text ?? "")\" is not recognized.",
                        diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSMessage.unrecognizedArgument"),
                        severity: .error
                    )
                    context.diagnose(Diagnostic(node: node, message: error))
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
                    fixIt: MessageMacro.getDDSInitializedFixIt(
                        typeName: typeName,
                        memberBlock: typeDecl.memberBlock
                    )
                )
            )
            return []
        }

        var outputs: [DeclSyntax] = []

        if hasConstructor && needsInitialized {
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

        // If there is a raw value, the type is automatically conformed to DDSCodable using the DDSRawRepresentable conformance
        if rawValue == nil {
            let error = DDSKitDiagnosticMessage(
                message: "DDSEnum: Types that are not raw representable are not supported yet. They must manually be conformed to DDSCodable.",
                diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSMessage.temp_notRawRepresentable"),
                severity: .error
            )
            context.diagnose(Diagnostic(node: node, message: error))
            context.diagnose(Diagnostic(node: typeDecl, message: error))
            return []
            // // Determine the smallest type to use for the descriminator
            // var descriminatorType: String
            // if cases.count > 0 { descriminatorType = "UInt8" }
            // if cases.count > UInt8.max { descriminatorType = "UInt16" }
            // if cases.count > UInt16.max { descriminatorType = "UInt32" }
            // // Create ddsTypeDescriptor
            // var typeDescriptorCases: [CodeBlockItemSyntax] = []
            // var calculateSizeCases: [CodeBlockItemSyntax] = []
            // var encodeCases: [CodeBlockItemSyntax] = []
            // var decodeCases: [CodeBlockItemSyntax] = []
            // var currentCaseId: UInt32 = 1 // Needs to start at 1 because 0 is reserved for the descriminator
            // for currentCase in cases {
            //     if let parameters = currentCase.parameters, parameters.count > 0 {
            //         if parameters.count == 1 {
            //             // Since there is only one parameter, we don't need to make it an anonymous struct
            //             let parameter = parameters.first!
            //             let paramterName = parameter.firstName ?? parameter.secondName ?? "param"
            //             typeDescriptorCases.append(
            //                 "builder.addCase(name: \"\(currentCase.name)\", caseId: \(raw: currentCaseId), type: \(raw: parameter.type).self)"
            //             )
            //             calculateSizeCases.append(
            //                 """
            //                 case .\(currentCase.name)(let \(paramterName)):
            //                     calculator.add(member: \(raw: currentCaseId), \(paramterName))
            //                 """
            //             )
            //             encodeCases.append(
            //                 """
            //                 case .\(currentCase.name)(let \(paramterName)):
            //                     try encoder.encode(member: 0, \(raw: currentCaseId) as \(raw: descriminatorType))
            //                     try encoder.encode(member: \(raw: currentCaseId), \(paramterName))
            //                 """
            //             )
            //             decodeCases.append(
            //                 """
            //                 case \(raw: currentCaseId):
            //                     assert(memberId == \(raw: currentCaseId), "\\(Self.self): ID != descriminator: got \\(memberId) -> expected \(raw: currentCaseId)")
            //                     var \(paramterName): Failure = .ddsInitialized
            //                     try decoder.decode(&\(paramterName))
            //                     self = .\(currentCase.name)(\(paramterName): \(paramterName))
            //                 """
            //             )
            //         } else {
            //             // If there are multiple parameters, we need to make it an anonymous struct
            //             var typeDescriptorCaseParameters: [CodeBlockItemSyntax] = []
            //             var calculateSizeCaseParameters: [CodeBlockItemSyntax] = []
            //             var encodeCaseParameters: [CodeBlockItemSyntax] = []
            //             var decodeCaseParameters: [CodeBlockItemSyntax] = []
            //             let parameterInfos = parameters.map { parameter in
            //                 let paramterName = parameter.firstName ?? parameter.secondName ?? "param"
            //                 return (name: paramterName, type: parameter.type.as(IdentifierTypeSyntax.self)!, parameter: parameter)
            //             }
            //             var currentMemberId: UInt32 = 0
            //             for parameter in parameterInfos {
            //                 typeDescriptorCases.append(
            //                     "builder.addMember(name: \"\(parameter.name)\", memberId: \(raw: currentMemberId), type: \(raw: parameter.type.name.text).self)"
            //                 )
            //                 calculateSizeCaseParameters.append(
            //                     """
            //                     calculator.add(member: \(raw: currentCaseId), \(parameter.name))
            //                     """
            //                 )
            //                 encodeCaseParameters.append(
            //                     """
            //                     try encoder.encode(member: \(raw: currentMemberId), \(parameter.name))
            //                     """
            //                 )

            //                 currentMemberId += 1
            //             }
            //         }
            //     } else {
            //         typeDescriptorCases.append(
            //             "builder.addCase(name: \"\(currentCase.name)\", caseId: \(raw: currentCaseId), build: { builder in })"
            //         )

            //     }
            //     currentCaseId += 1
            // }

            // let typeDescriptorDecl = VariableDeclSyntax(
            //     modifiers: [.init(name: .keyword(.public)), .init(name: .keyword(.static))],
            //     bindingSpecifier: "var",
            //     bindings: [
            //         PatternBindingSyntax(
            //             pattern: IdentifierPatternSyntax(identifier: "ddsTypeDescriptor"),
            //             typeAnnotation: TypeAnnotationSyntax(type: "DDSKit.DDSTypeDescriptor" as TypeSyntax),
            //             accessorBlock: AccessorBlockSyntax(
            //                 accessors: .getter("""
            //                     .createEnum(name: \(name), descriminator: \(raw: descriminatorType).ddsTypeDescriptor) { builder in
            //                         \(CodeBlockItemListSyntax(typeDescriptorCases))
            //                     }
            //                 """)
            //             )
            //         )
            //     ]
            // )
            // outputs.append(.init(typeDescriptorDecl))
            // let calculateSizeDecl = FunctionDeclSyntax(
            //     modifiers: [.init(name: .keyword(.public))],
            //     name: "calculateDDSSize",
            //     signature: FunctionSignatureSyntax(
            //         parameterClause: FunctionParameterClauseSyntax(parameters: [
            //             FunctionParameterSyntax(
            //                 firstName: "calculator",
            //                 type: AttributedTypeSyntax(
            //                     specifiers: [.init(SimpleTypeSpecifierSyntax(specifier: .keyword(.inout)))],
            //                     baseType: "DDSKit.DDSSizeCalculator" as TypeSyntax
            //                 )
            //             )
            //         ])
            //     ),
            //     body: CodeBlockSyntax(statements: """
            //         calculator.withStruct { calculator in
            //             \(CodeBlockItemListSyntax(calculateSizeCases))
            //         }
            //     """)
            // )
            // outputs.append(.init(calculateSizeDecl))
            // let encodeDecl = FunctionDeclSyntax(
            //     modifiers: [.init(name: .keyword(.public))],
            //     name: "ddsEncode",
            //     signature: FunctionSignatureSyntax(
            //         parameterClause: FunctionParameterClauseSyntax(parameters: [
            //             FunctionParameterSyntax(
            //                 firstName: "encoder",
            //                 type: AttributedTypeSyntax(
            //                     specifiers: [.init(SimpleTypeSpecifierSyntax(specifier: .keyword(.inout)))],
            //                     baseType: "DDSKit.DDSEncoder" as TypeSyntax
            //                 )
            //             )
            //         ]),
            //         effectSpecifiers: FunctionEffectSpecifiersSyntax(
            //             throwsClause: ThrowsClauseSyntax(
            //                 throwsSpecifier: .keyword(.throws),
            //                 leftParen: .leftParenToken(), type: "DDSKit.DDSEncoder.EncodingError" as TypeSyntax, rightParen: .rightParenToken()
            //             )
            //         )
            //     ),
            //     body: CodeBlockSyntax(statements: """
            //         try encoder.withStruct { encoder throws(DDSKit.DDSEncoder.EncodingError) in
            //             \(CodeBlockItemListSyntax(encodeCases))
            //         }
            //     """)
            // )
            // outputs.append(.init(encodeDecl))
            // let decodeDecl = FunctionDeclSyntax(
            //     modifiers: [.init(name: .keyword(.public)), .init(name: .keyword(.mutating))],
            //     name: "ddsDecode",
            //     signature: FunctionSignatureSyntax(
            //         parameterClause: FunctionParameterClauseSyntax(parameters: [
            //             FunctionParameterSyntax(
            //                 firstName: "decoder",
            //                 type: AttributedTypeSyntax(
            //                     specifiers: [.init(SimpleTypeSpecifierSyntax(specifier: .keyword(.inout)))],
            //                     baseType: "DDSKit.DDSDecoder" as TypeSyntax
            //                 )
            //             )
            //         ]),
            //         effectSpecifiers: FunctionEffectSpecifiersSyntax(
            //             throwsClause: ThrowsClauseSyntax(
            //                 throwsSpecifier: .keyword(.throws),
            //                 leftParen: .leftParenToken(), type: "DDSKit.DDSDecoder.DecodingError" as TypeSyntax, rightParen: .rightParenToken()
            //             )
            //         )
            //     ),
            //     body: CodeBlockSyntax(statements: """
            //         try decoder.withStruct { decoder, member throws(DDSKit.DDSDecoder.DecodingError) in
            //             switch member {
            //                 \(CodeBlockItemListSyntax(decodeCases))
            //                 default:
            //                     throw .unknownMember
            //             }
            //         }
            //     """)
            // )
            // outputs.append(.init(decodeDecl))
        }

        return outputs
    }
}

extension EnumMacro: ExtensionMacro {
    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) -> [ExtensionDeclSyntax] {
        let rawValue: IdentifierTypeSyntax?
        do {
            let info = try evaluateType(of: node, parent: declaration, context: nil)
            rawValue = info.rawValue
        } catch {
            return []
        }

        var extensions: [ExtensionDeclSyntax] = []

        if rawValue != nil {
            extensions.append(
                try! ExtensionDeclSyntax(
                    "extension \(type): DDSRawRepresentable {}"
                )
            )
            if ddsLoaningTypes.contains(rawValue!.name.text) {
                extensions.append(
                    try! ExtensionDeclSyntax(
                        "extension \(type): DDSLoaningCodable {}"
                    )
                )
            }
        }

        extensions.append(try! ExtensionDeclSyntax("extension \(type): DDSCodable {}"))
        return extensions
    }
}
