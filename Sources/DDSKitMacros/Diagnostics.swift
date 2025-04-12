/**
 * Diagnostics.swift
 * DDSKitMacros
 * 
 * Created by Hunter Baker on 4/07/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
import SwiftDiagnostics
import SwiftSyntax

struct DDSKitDiagnosticMessage: DiagnosticMessage, Error {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity
}

extension DDSKitDiagnosticMessage: FixItMessage {
    var fixItID: MessageID { diagnosticID }
}

struct DDSKitFixItMessage: FixItMessage {
    let message: String
    let fixItID: MessageID
}
