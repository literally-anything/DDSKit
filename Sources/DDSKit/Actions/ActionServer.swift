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

/// A server for an action client.
/// Actions are an implementation of the request reply pattern using topics.
public final class DDSActionServer<Request: DDSMessage, Reply: DDSMessage>: Sendable {
    /// The type of the handler function for the action server.
    public typealias RequestHandler = @Sendable (borrowing Request) -> Reply

    /// The logger for the action server.
    private let logger: Logger
    /// The subscriber for the request.
    private let subscriber: DDSSubscriber<Request>
    /// The publisher for the reply.
    private let publisher: DDSPublisher<Reply>
    /// The handler callback for the request.
    private let requestHandler: RequestHandler

    /// The participant for the action server.
    public var participant: DDSParticipant {
        subscriber.participant
    }

    /// Initializes a new action server.
    /// - Parameters:
    ///   - participant: The participant to use for the action.
    ///   - actionName: The base name of the action.
    ///   - publisherSettings: A list of settings to apply to the request publisher.
    ///   - subscriberSettings: A list of settings to apply to the reply subscriber.
    ///   - handler: The handler for the request.
    /// - Throws: If the subscriber cannot be created.
    public convenience init(
        participant: DDSParticipant, name actionName: String,
        subscriberSettings: [DDSSubscriber<Request>.Setting] = [], publisherSettings: [DDSPublisher<Reply>.Setting] = [],
        handler: @escaping RequestHandler
    ) throws(DDSError) {
        let (requestTopic, replyTopic) = getActionTopicNames(base: actionName)

        self.init(
            requestSubscriber: try participant.subscribe(to: requestTopic, type: Request.self, settings: subscriberSettings),
            replyPublisher: try participant.publish(to: replyTopic, type: Reply.self, settings: publisherSettings),
            handler: handler
        )
    }

    /// Initializes a new action server.
    /// - Parameters:
    ///   - requestTopic: The topic for the request.
    ///   - replyTopic: The topic for the reply.
    ///   - subscriberSettings: A list of settings to apply to the request subscriber.
    ///   - publisherSettings: A list of settings to apply to the reply publisher.
    ///   - handler: The handler for the request.
    /// - Throws: If the subscriber cannot be created.
    public convenience init(
        requestTopic: DDSTopic<Request>, replyTopic: DDSTopic<Reply>,
        subscriberSettings: [DDSSubscriber<Request>.Setting] = [], publisherSettings: [DDSPublisher<Reply>.Setting] = [],
        handler: @escaping RequestHandler
    ) throws(DDSError) {
        self.init(
            requestSubscriber: try requestTopic.subscribe(settings: subscriberSettings),
            replyPublisher: try replyTopic.publish(settings: publisherSettings),
            handler: handler
        )
    }

    /// Initializes a new action server.
    /// - Parameters:
    ///   - requestSubscriber: The subscriber for the request.
    ///   - replyPublisher: The publisher for the reply.
    ///   - handler: The handler for the request.
    /// - Throws: If the subscriber cannot be created.
    public init(
        requestSubscriber: DDSSubscriber<Request>, replyPublisher: DDSPublisher<Reply>,
        handler: @escaping RequestHandler
    ) {
        logger = Logger(label: "DDSActionServer(\(requestSubscriber.topic.name), \(replyPublisher.topic.name))")

        subscriber = requestSubscriber
        publisher = replyPublisher

        requestHandler = handler

        requestSubscriber.registerMessageCallback { [unowned self] message, metadata in
            let reply = requestHandler(message)
            do throws(DDSError) {
                try publisher.publishWithMetadata(reply, metadata: .init(relatedIdentifier: metadata.identifier))
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
    ///   - handler: The handler for the request.
    /// - Throws: If the subscriber cannot be created.
    public func createActionClient<Request: DDSMessage, Reply: DDSMessage>(
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
