/**
 * ActionServer.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 1/23/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
public import Logging
internal import Synchronization

/// An action server with support for throwing errors as the result.
/// This is actually just a type alias for DDSActionServer<Request, Result<Success, Failure>>.
public typealias DDSThrowingActionServer<Request: DDSMessage, Success: DDSCodable, Failure: DDSCodable & Error> = DDSActionServer<Request, Result<Success, Failure>>

/// A server for an action client.
/// Actions are an implementation of the request reply pattern using topics.
public final class DDSActionServer<Request: DDSMessage, Reply: DDSMessage>: Sendable {
    /// The type of the handler function for the action server.
    public typealias RequestHandler = @Sendable (borrowing Request) -> Reply

    /// The logger for the action server.
    @usableFromInline
    internal let logger: Logger
    /// The subscriber for the request.
    @usableFromInline
    internal let subscriber: DDSSubscriber<Request>
    /// The publisher for the reply.
    @usableFromInline
    internal let publisher: DDSPublisher<Reply>
    /// The handler callback for the request.
    @usableFromInline
    internal let requestHandler: RequestHandler

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
    ///   - convention: The naming convention to use for the action. If this is `.ros2`, the action will interop with ROS2 services.
    ///   - handler: The handler for the request.
    /// - Throws: If the subscriber cannot be created.
    @inlinable
    public convenience init(
        participant: DDSParticipant, name actionName: String,
        subscriberSettings: [DDSSubscriber<Request>.Setting] = [], publisherSettings: [DDSPublisher<Reply>.Setting] = [],
        convention: DDSNamespace.NamingConvention = .default,
        handler: @escaping RequestHandler
    ) throws(DDSError) {
        let requestTopic = try DDSTopic<Request>(
            participant: participant, topic: actionName, typeSupport: Request.ddsTypeSupport,
            nameInfo: (.actionRequest, convention)
        )
        let replyTopic = try DDSTopic<Reply>(
            participant: participant, topic: actionName, typeSupport: Reply.ddsTypeSupport,
            nameInfo: (.actionReply, convention)
        )

        try self.init(
            requestTopic: requestTopic,
            replyTopic: replyTopic,
            subscriberSettings: subscriberSettings, publisherSettings: publisherSettings,
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
    @inlinable
    public init(
        requestTopic: DDSTopic<Request>, replyTopic: DDSTopic<Reply>,
        subscriberSettings: [DDSSubscriber<Request>.Setting] = [], publisherSettings: [DDSPublisher<Reply>.Setting] = [],
        handler: @escaping RequestHandler
    ) throws(DDSError) {
        assert(requestTopic.participant === replyTopic.participant, "Request and reply topics should be on the same participant")

        logger = Logger(label: "DDSActionServer(\(requestTopic.name), \(replyTopic.name))")

        logger.trace("Creating action server with request topic: \(requestTopic.name), and reply topic: \(replyTopic.name)")

        subscriber = try requestTopic.subscribe(settings: subscriberSettings)
        publisher = try replyTopic.publish(settings: publisherSettings)

        requestHandler = handler

        // Workaround for swift compiler bug
        let callback: @Sendable (borrowing Request, borrowing DDSSubscriber<Request>.MessageMetadata) -> Void
        callback = { [unowned self] message, metadata in
            logger.trace("Got request from client: \(metadata.senderEntityIdentifier)")

            let reply = requestHandler(message)
            do throws(DDSError) {
                try publisher.publishWithMetadata(reply, metadata: .init(relatedIdentifier: metadata.identifier))
            } catch {
                logger.error("Error while publishing reply: \(error)")
            }
        }
        subscriber.registerMessageCallback(callback)
    }

    deinit {
        logger.trace("Deinitializing action server: \(description)")
        subscriber.dataCallbacks.withLock { callbacks in
            callbacks.removeAll()
        }
    }
}

extension DDSActionServer where Reply: DDSActionResult /* This just means that it is a Result where both Failure and Success are DDSCodable */ {
    /// Initializes a new action server for a Reply that is a Result,
    /// - Parameters:
    ///   - participant: The participant to use for the action.
    ///   - actionName: The base name of the action.
    ///   - publisherSettings: A list of settings to apply to the request publisher.
    ///   - subscriberSettings: A list of settings to apply to the reply subscriber.
    ///   - handler: The handler for the request. This should return a Reply.Succes and can throw a Reply.Failure.
    /// - Throws: If the subscriber cannot be created.
    @inlinable
    public convenience init(
        participant: DDSParticipant, name actionName: String,
        subscriberSettings: [DDSSubscriber<Request>.Setting] = [], publisherSettings: [DDSPublisher<Reply>.Setting] = [],
        handler: @escaping @Sendable (borrowing Request) throws(Reply.Failure) -> Reply.Success
    ) throws(DDSError) {
        try self.init(
            participant: participant, name: actionName,
            subscriberSettings: subscriberSettings, publisherSettings: publisherSettings
        ) { message throws(Never) in
            Reply { () throws(Reply.Failure) in
                try handler(message)
            }
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
    ///   - convention: The naming convention to use for the action. If this is `.ros2`, the action will interop with ROS2 services.
    ///   - handler: The handler for the request.
    /// - Throws: If the subscriber cannot be created.
    public func createActionServer<Request: DDSMessage, Reply: DDSMessage>(
        name: String,
        request: Request.Type, reply: Reply.Type,
        subscriberSettings: [DDSSubscriber<Request>.Setting] = [], publisherSettings: [DDSPublisher<Reply>.Setting] = [],
        convention: DDSNamespace.NamingConvention = .default,
        handler: @escaping DDSActionServer<Request, Reply>.RequestHandler
    ) throws(DDSError) -> DDSActionServer<Request, Reply> {
        try DDSActionServer(
            participant: self,
            name: name,
            subscriberSettings: subscriberSettings, publisherSettings: publisherSettings,
            convention: convention,
            handler: handler
        )
    }
}
