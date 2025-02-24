/**
 * ActionServer.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 1/23/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import Synchronization
internal import Logging

/// Takes the base name of an action and returns the request and reply topic names.
/// - Parameter base: The name of the action.
/// - Returns: A tuple with the request and reply topic names (in that order).
internal func getActionTopicNames(base: String) -> (request: String, reply: String) {
    return ("rq/" + base, "rr/" + base)
}

public final class DDSActionServer<Request: DDSCodable, Reply: DDSCodable>: Sendable {
    public typealias RequestHandler = @Sendable (borrowing Request) -> Reply

    private let logger: Logger
    private let subscriber: DDSSubscriber<Request>
    private let publisher: DDSPublisher<Reply>
    private let resignOnCancel: Bool
    internal let requestHandler: RequestHandler

    public convenience init(
        participant: DDSParticipant, name actionName: String,
        subscriberSettings: [DDSSubscriber<Request>.Setting] = [], publisherSettings: [DDSPublisher<Reply>.Setting] = [],
        resignOnCancel: Bool = true,
        handler: @escaping RequestHandler
    ) throws(DDSError) {
        let (requestTopic, replyTopic) = getActionTopicNames(base: actionName)

        self.init(
            requestSubscriber: try participant.subscribe(to: requestTopic, type: Request.self, settings: subscriberSettings),
            replyPublisher: try participant.publish(to: replyTopic, type: Reply.self, settings: publisherSettings),
            resignOnCancel: resignOnCancel,
            handler: handler
        )
    }

    public convenience init(
        requestTopic: DDSTopic<Request>, replyTopic: DDSTopic<Reply>,
        subscriberSettings: [DDSSubscriber<Request>.Setting] = [], publisherSettings: [DDSPublisher<Reply>.Setting] = [],
        resignOnCancel: Bool = true,
        handler: @escaping RequestHandler
    ) throws(DDSError) {
        self.init(
            requestSubscriber: try requestTopic.subscribe(settings: subscriberSettings),
            replyPublisher: try replyTopic.publish(settings: publisherSettings),
            resignOnCancel: resignOnCancel,
            handler: handler
        )
    }

    public init(
        requestSubscriber: DDSSubscriber<Request>, replyPublisher: DDSPublisher<Reply>,
        resignOnCancel: Bool = true,
        handler: @escaping RequestHandler
    ) {
        logger = Logger(label: "DDSActionServer(\(requestSubscriber.topic.name), \(replyPublisher.topic.name))")

        subscriber = requestSubscriber
        publisher = replyPublisher

        self.resignOnCancel = resignOnCancel

        requestHandler = handler

        requestSubscriber.registerMessageCallback { [unowned self] message, indentifiers in
            if (resignOnCancel) {

            }
            let reply = requestHandler(message)
            do throws(DDSError) {
                try publisher.publishWithIdentifiers(reply, related: indentifiers.identifier)
            } catch {
                logger.error("Error while publishing reply: \(error)")
            }
        }
    }

    deinit {
        subscriber.dataCallbacks.withLock { callbacks in
            callbacks.removeAll()
        }
    }
}

extension DDSActionServer: CustomStringConvertible {
    public var description: String {
        "DDSActionServer(request: (\(subscriber.topic.name), type: \(subscriber.topic.typeName)), reply: (\(publisher.topic.name), type: \(publisher.topic.typeName)))"
    }
}

extension DDSParticipant {
    /// Creates a new action server on this participant.
    /// - Parameters:
    ///   - name: The base name of the topics used in the action.
    ///   - request: The message request data type.
    ///   - reply: The message reply data type.
    ///   - publisherSettings: A list of settings to apply to the request publisher.
    ///   - subscriberSettings: A list of settings to apply to the reply subscriber.
    /// - Throws: If the subscriber cannot be created.
    public func createActionClient<Request: DDSCodable, Reply: DDSCodable>(
        name: String,
        request: Request.Type, reply: Reply.Type,
        subscriberSettings: [DDSSubscriber<Request>.Setting] = [], publisherSettings: [DDSPublisher<Reply>.Setting] = [],
        handler: @escaping DDSActionServer<Request, Reply>.RequestHandler
    ) throws(DDSError) -> DDSActionServer<Request, Reply> {
        try DDSActionServer(
            participant: self,
            name: name,
            subscriberSettings: subscriberSettings, publisherSettings: publisherSettings,
            handler: handler
        )
    }
}
