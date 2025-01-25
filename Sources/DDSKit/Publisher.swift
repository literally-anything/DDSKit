/**
 * Publisher.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 8/07/2024
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
import _CFastDDS

open class PublisherOld: @unchecked Sendable {
    public let raw: OpaquePointer
    public let participant: DomainParticipantOld
    public var qos: Qos {
        get {
            .init(from: fastdds._Publisher.getQos(raw))
        }
        set(newValue) {
            let ret = fastdds._Publisher.setQos(raw, newValue.raw)
            assert(ret == FastDDSError.OK)
        }
    }

    public convenience init?(participant: DomainParticipantOld, profile: String) {
        let publisherPtr = fastdds._Publisher.create(participant.raw, .init(profile))
        guard (publisherPtr != nil) else {
            return nil
        }
        self.init(from: publisherPtr!, participant: participant)
    }
    public convenience init?(participant: DomainParticipantOld, qos: Qos? = nil) {
        let publisherPtr = fastdds._Publisher.create(participant.raw, (qos ?? .getBase(for: participant)).raw)
        guard (publisherPtr != nil) else {
            return nil
        }
        self.init(from: publisherPtr!, participant: participant)
    }
    public init(from publisherPtr: OpaquePointer, participant domainParticipant: DomainParticipantOld) {
        raw = publisherPtr
        participant = domainParticipant
    }
    deinit {
        let ret = fastdds._Publisher.destroy(raw)
        assert(ret == FastDDSError.OK, "Failed to destroy Publisher: \(String(describing: FastDDSError(rawValue: ret)))")
    }

    public struct Qos: Sendable, Equatable {
        public var raw: fastdds._Publisher.PublisherQos

        @inlinable public static func == (lhs: Qos, rhs: Qos) -> Bool {
            fastdds._Publisher.compareQos(lhs.raw, rhs.raw)
        }

        @inlinable public init() {
            self.init(from: fastdds._Publisher.PublisherQos())
        }
        public init(from qos: fastdds._Publisher.PublisherQos) {
            raw = qos
        }

        @inlinable public static func getBase(for participant: DomainParticipantOld) -> Qos {
            Qos(from: fastdds._Publisher.getDefaultQos(participant.raw))
        }
    }
}
