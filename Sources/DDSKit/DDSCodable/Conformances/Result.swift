/**
 * Result.swift
 * Conformances
 *
 * Created by Hunter Baker on 3/10/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */

// For use in Results. It will never be initialized when it is the error type, so it works fine. It just can't be used in an actual DDS type that is sent.
extension Never: DDSCodable {
    public static var ddsInitialized: Never {
        fatalError("Never cannot be used in a DDS type because it can never be initialized")
    }
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        .createStruct(name: "Swift.Never", isBounded: true, isPlain: true) { _ in }
    }
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {}
    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {}
    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {}
}

extension Result: DDSCodable, DDSMessage where Success: DDSCodable, Failure: DDSCodable {
    @_alwaysEmitIntoClient
    public static var ddsInitialized: Self {
        .success(.ddsInitialized)
    }

    @_alwaysEmitIntoClient
    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        .createEnum(
            name: "Swift.Result<\(Success.ddsTypeDescriptor.name), \(Failure.ddsTypeDescriptor.name)>",
            descriminator: Bool.ddsTypeDescriptor
        ) { builder in
            builder.addCase(name: "success", caseId: 1, type: Success.self)
            builder.addCase(name: "failure", caseId: 2, type: Failure.self)
        }
    }

    @_alwaysEmitIntoClient
    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        calculator.withStruct { calculator in
            calculator.add(member: 0, Bool())
            switch self {
                case .success(let result):
                    calculator.add(member: 1, result)
                case .failure(let error):
                    calculator.add(member: 2, error)
            }
        }
    }

    @_alwaysEmitIntoClient
    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        try encoder.withStruct { encoder throws(DDSEncoder.EncodingError) in
            switch self {
                case .success(let result):
                    try encoder.encode(member: 0, true)  // descriminator

                    try encoder.encode(member: 1, result)
                case .failure(let error):
                    try encoder.encode(member: 0, false)  // descriminator

                    try encoder.encode(member: 2, error)
            }
        }
    }

    @_alwaysEmitIntoClient
    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        var descriminator: Bool = false

        try decoder.withStruct { decoder, memberId throws(DDSDecoder.DecodingError) in
            switch memberId {
                case 0:
                    try decoder.decode(&descriminator)
                default:
                    switch descriminator {
                        case true:
                            assert(memberId == 1, "Member ID does not match descriminator: \(Self.self): got \(memberId) -> expected 1")
                            var result: Success = .ddsInitialized
                            try decoder.decode(&result)
                            self = .success(result)
                        case false:
                            assert(memberId == 2, "Member ID does not match descriminator: \(Self.self): got \(memberId) -> expected 2")
                            var error: Failure = .ddsInitialized
                            try decoder.decode(&error)
                            self = .failure(error)
                    }
            }
        }
    }

    @_alwaysEmitIntoClient
    public static var ddsTypeSupport: DDSTypeSupport {
        DDSTypeSupport(name: ddsTypeDescriptor.name, type: Self.self)
    }
}

extension Result: DDSLoaningCodable where Success: DDSLoaningCodable, Failure: DDSLoaningCodable {}
