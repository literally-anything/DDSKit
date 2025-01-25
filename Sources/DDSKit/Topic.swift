/**
 * Topic.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 8/19/2024
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
public import enum _CFastDDS.fastdds
import _FastDDSHelpers

public final class TopicOld: @unchecked Sendable {
    public typealias InconsistentTopicCallback = (borrowing fastdds.DDSInconsistentTopicStatus) -> Void

    public let raw: OpaquePointer
    public let participant: DomainParticipantOld
    private var callbacks = TopicCallbacks()
    private let listener: UnsafeMutablePointer<fastdds._Topic.Listener>
    private var inconsistentTopicCallback: InconsistentTopicCallback?
    public var qos: Qos {
        get {
            .init(from: fastdds._Topic.getQos(raw))
        }
        set(newValue) {
            let ret = fastdds._Topic.setQos(raw, newValue.raw)
            assert(ret == FastDDSError.OK)
        }
    }

    public convenience init?(participant: DomainParticipantOld, name: String, typeName: String, profile: String) throws {
        let topicPtr = fastdds._Topic.create(participant.raw, .init(name), .init(typeName), .init(profile))
        guard (topicPtr != nil) else {
            return nil
        }
        try self.init(from: topicPtr!, participant: participant)
    }
    public convenience init?(participant: DomainParticipantOld, name: String, typeName: String, qos: Qos? = nil) throws {
        let topicPtr = fastdds._Topic.create(participant.raw, .init(name), .init(typeName), (qos ?? .getBase(for: participant)).raw)
        guard (topicPtr != nil) else {
            return nil
        }
        try self.init(from: topicPtr!, participant: participant)
    }
    public init(from topicPtr: OpaquePointer, participant domainParticipant: DomainParticipantOld) throws {
        raw = topicPtr
        participant = domainParticipant

        listener = withUnsafePointer(to: &callbacks) { ptr in
            fastdds._Topic.createListener(OpaquePointer(ptr))
        }
        callbacks.setCallbacks { [unowned self] status in
            self.inconsistentTopicCallback?(UnsafePointer<fastdds.DDSInconsistentTopicStatus>(OpaquePointer(status)).pointee)
        }
        try FastDDSError.check(code: fastdds._Topic.setListener(raw, listener, fastdds._StatusMask.inconsistent_topic()))
    }
    deinit {
        let ret = fastdds._Topic.destroy(raw)
        assert(ret == FastDDSError.OK, "Failed to destroy Topic: \(String(describing: FastDDSError(rawValue: ret)))")

        fastdds._Topic.destroyListener(listener)
    }

    public func onInconsistentTopic(perform action: @escaping InconsistentTopicCallback) {
        inconsistentTopicCallback = action
    }

    public struct Qos: Sendable, Equatable {
        public var raw: fastdds._Topic.TopicQos

        public static func == (lhs: Qos, rhs: Qos) -> Bool {
            fastdds._Topic.compareQos(lhs.raw, rhs.raw)
        }

        public init() {
            self.init(from: fastdds._Topic.TopicQos())
        }
        public init(from qos: fastdds._Topic.TopicQos) {
            raw = qos
        }

        public static func getBase(for participant: DomainParticipantOld) -> Qos {
            Qos(from: fastdds._Topic.getDefaultQos(participant.raw))
        }
    }
}
