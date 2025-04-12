/**
 * IgnoredMacro.swift
 * DDSKitMacros
 * 
 * Created by Hunter Baker on 4/07/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

/// A macro that ignores the declaration it is applied to.
/// This doesn't actually do anything, it's just used as a marker of ignored members.
struct IgnoredMacro: PeerMacro {
    private static func getFixIt(type: some WithAttributesSyntax & SyntaxProtocol) -> FixIt {
        return FixIt(
            message: DDSKitFixItMessage(
                message: "Remove @DDSIgnored",
                fixItID: MessageID(domain: "DDSKitMacros", id: "DDSIgnored.remove")
            ),
            changes: [
                .replace(
                    oldNode: Syntax(type.attributes),
                    newNode: Syntax({
                        var fixedAttributes = type.attributes
                        fixedAttributes = fixedAttributes.filter {
                            $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text != "DDSIgnored"
                        }
                        return fixedAttributes.formatted()
                    }())
                )
            ]
        )
    }

    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let baseWarning = DDSKitDiagnosticMessage(
            message: "DDSIgnored has no effect when applied to anything that isn't a member variable of a type annoteted with @DDSMessage.",
            diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSIgnored.structMemberVarOnly"),
            severity: .warning
        )
        guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
            // If it is an attributed type then we can add a fixit to remove the attribute
            guard let attributedType = declaration.asProtocol(WithAttributesSyntax.self) else {
                context.diagnose(Diagnostic(node: node, message: baseWarning))
                return []
            }
            let removeFixIt = getFixIt(type: attributedType)
            context.diagnose(Diagnostic(node: node, message: baseWarning, fixIt: removeFixIt))
            return []
        }

        let removeFixIt = getFixIt(type: varDecl)

        if let staticModifier = varDecl.modifiers.first(where: { $0.name.tokenKind == .keyword(.static) }) {
            let warning = DDSKitDiagnosticMessage(
                message: "DDSIgnored has no effect on static members. (They aren't in the DDSMessage normally)",
                diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSIgnored.notStatic"),
                severity: .warning
            )
            context.diagnose(
                Diagnostic(
                    node: staticModifier,
                    message: warning,
                    highlights: [Syntax(node), Syntax(staticModifier)],
                    fixIt: removeFixIt
                )
            )
            context.diagnose(
                Diagnostic(
                    node: node,
                    message: warning,
                    highlights: [Syntax(node), Syntax(staticModifier)],
                    fixIt: removeFixIt
                )
            )
        }
        if varDecl.bindingSpecifier.tokenKind != .keyword(.var) {
            let warning = DDSKitDiagnosticMessage(
                message: "DDSIgnored should be applied to a `var`. (Only vars are in the DDSMessage normally)",
                diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSIgnored.varOnly"),
                severity: .warning
            )
            context.diagnose(
                Diagnostic(
                    node: varDecl.bindingSpecifier,
                    message: warning,
                    highlights: [Syntax(node), Syntax(varDecl.bindingSpecifier)],
                    fixIt: removeFixIt
                )
            )
            context.diagnose(
                Diagnostic(
                    node: node,
                    message: warning,
                    highlights: [Syntax(node), Syntax(varDecl.bindingSpecifier)],
                    fixIt: removeFixIt
                )
            )
        }
        
        if let parent = context.lexicalContext.first {
            let warning = DDSKitDiagnosticMessage(
                message: "DDSIgnored should be applied to a member of a struct annotated with @DDSMessage.",
                diagnosticID: MessageID(domain: "DDSKitMacros", id: "DDSIgnored.messageMemberOnly"),
                severity: .warning
            )
            // We never like classes
            // But when it's a struct, we need to ensure it's annotated with @DDSMessage before being ok with it
            if let parentClass = parent.as(ClassDeclSyntax.self) {
                context.diagnose(
                    Diagnostic(
                        node: parentClass.classKeyword,
                        message: warning,
                        highlights: [Syntax(node), Syntax(parentClass.classKeyword)],
                        fixIt: removeFixIt
                    )
                )
                context.diagnose(
                    Diagnostic(
                        node: node,
                        message: warning,
                        highlights: [Syntax(node), Syntax(parentClass.classKeyword)],
                        fixIt: removeFixIt
                    )
                )
            } else if let parentStruct = parent.as(StructDeclSyntax.self) {
                if !parentStruct.attributes.contains(where: {
                    $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "DDSMessage"
                }) {
                    context.diagnose(Diagnostic(node: node, message: warning, fixIt: removeFixIt))
                }
            }
        } else {
            context.diagnose(Diagnostic(node: node, message: baseWarning, fixIt: removeFixIt))
        }

        return []
    }
}
