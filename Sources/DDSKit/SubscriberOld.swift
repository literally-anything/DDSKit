/**
 * Subscriber.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 8/07/2024
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
import _CFastDDS

open class SubscriberOld: @unchecked Sendable {
    public let raw: OpaquePointer
    public let participant: DomainParticipantOld
    public var qos: Qos {
        get {
            .init(from: fastdds._Subscriber.getQos(raw))
        }
        set(newValue) {
            let ret = fastdds._Subscriber.setQos(raw, newValue.raw)
            assert(ret == FastDDSError.OK)
        }
    }

    public convenience init?(participant: DomainParticipantOld, profile: String) {
        let subscriberPtr = fastdds._Subscriber.create(participant.raw, .init(profile))
        guard (subscriberPtr != nil) else {
            return nil
        }
        self.init(from: subscriberPtr!, participant: participant)
    }
    public convenience init?(participant: DomainParticipantOld, qos: Qos? = nil) {
        let subscriberPtr = fastdds._Subscriber.create(participant.raw, (qos ?? .getBase(for: participant)).raw)
        guard (subscriberPtr != nil) else {
            return nil
        }
        self.init(from: subscriberPtr!, participant: participant)
    }
    public init(from subscriberPtr: OpaquePointer, participant domainParticipant: DomainParticipantOld) {
        raw = subscriberPtr
        participant = domainParticipant
    }
    deinit {
        let ret = fastdds._Subscriber.destroy(raw)
        assert(ret == FastDDSError.OK, "Failed to destroy Subscriber: \(String(describing: FastDDSError(rawValue: ret)))")
    }

    public struct Qos: Sendable, Equatable {
        public var raw: fastdds._Subscriber.SubscriberQos

        @inlinable public static func == (lhs: Qos, rhs: Qos) -> Bool {
            fastdds._Subscriber.compareQos(lhs.raw, rhs.raw)
        }

        @inlinable public init() {
            self.init(from: fastdds._Subscriber.SubscriberQos())
        }
        public init(from qos: fastdds._Subscriber.SubscriberQos) {
            raw = qos
        }

        @inlinable public static func getBase(for participant: DomainParticipantOld) -> Qos {
            Qos(from: fastdds._Subscriber.getDefaultQos(participant.raw))
        }
    }
}
