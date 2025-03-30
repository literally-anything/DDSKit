/**
 * Duration.swift
 * Conformances
 * 
 * Created by Hunter Baker on 3/17/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */

extension Duration: DDSCodable, DDSLoaningCodable {
    public static var ddsInitialized: Self {
        .init(secondsComponent: 0, attosecondsComponent: 0)
    }

    public static var ddsTypeDescriptor: DDSTypeDescriptor {
        .createStruct(name: "Swift.Duration") { builder in
            builder.addMember(type: Int64.self, name: "seconds", memberId: 0)
            builder.addMember(type: Int64.self, name: "attoseconds", memberId: 1)
        }
    }

    public func calculateDDSSize(calculator: inout DDSSizeCalculator) {
        calculator.withStruct { calculator in
            calculator.add(member: 0, components.seconds)
            calculator.add(member: 1, components.attoseconds)
        }
    }

    public func ddsEncode(encoder: inout DDSEncoder) throws(DDSEncoder.EncodingError) {
        try encoder.withStruct { encoder throws(DDSEncoder.EncodingError) in
            try encoder.encode(member: 0, components.seconds)
            try encoder.encode(member: 1, components.attoseconds)
        }
    }

    public mutating func ddsDecode(decoder: inout DDSDecoder) throws(DDSDecoder.DecodingError) {
        var seconds = components.seconds
        var attoseconds = components.attoseconds
        try decoder.withStruct { decoder, memberId throws(DDSDecoder.DecodingError) in
            switch memberId {
            case 0:
                try decoder.decode(&seconds)
            case 1:
                try decoder.decode(&attoseconds)
            default:
                throw .unknownMember
            }
        }
        self = .init(secondsComponent: seconds, attosecondsComponent: attoseconds)
    }
}
