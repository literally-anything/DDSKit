/**
 * ActionClient.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 1/23/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
public import Logging
public import Synchronization
internal import _CFastDDS

/// An action client with support for throwing errors as the result.
/// This is actually just a type alias for DDSActionClient<Request, Result<Success, Failure>>.
public typealias DDSThrowingActionClient<Request: DDSMessage, Success: DDSCodable, Failure: DDSCodable & Error> = DDSActionClient<Request, Result<Success, Failure>>

/// A client for an action server.
/// Actions are an implementation of the request reply pattern using topics.
public final class DDSActionClient<Request: DDSMessage, Reply: DDSMessage>: Sendable {
    /// The logger for the action client.
    @usableFromInline
    internal let logger: Logger
    /// The publisher for the request.
    @usableFromInline
    internal let publisher: DDSPublisher<Request>
    /// The subscriber for the reply.
    @usableFromInline
    internal let subscriber: DDSSubscriber<Reply>
    /// The active actions that are waiting for a reply.
    /// This maps the message identifier of the request to the continuation that is waiting for the reply.
    @usableFromInline
    internal let activeActions: Mutex<[DDSMessageIdentifier: UnsafeContinuation<Reply, Never>]> = Mutex([:])

    /// The participant for the action client.
    public var participant: DDSParticipant {
        publisher.participant
    }

    /// Initializes a new action client.
    /// - Parameters:
    ///   - participant: The participant to use for the action.
    ///   - actionName: The base name of the action.
    ///   - publisherSettings: A list of settings to apply to the request publisher.
    ///   - subscriberSettings: A list of settings to apply to the reply subscriber.
    ///   - convention: The naming convention to use for the action. If this is `.ros2`, the action will interop with ROS2 services.
    /// - Throws: If the subscriber cannot be created.
    @inlinable
    public convenience init(
        participant: DDSParticipant, name actionName: String,
        publisherSettings: [DDSPublisher<Request>.Setting] = [], subscriberSettings: [DDSSubscriber<Reply>.Setting] = [],
        convention: DDSNamespace.NamingConvention = .default
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
            publisherSettings: publisherSettings,
            subscriberSettings: subscriberSettings
        )
    }

    /// Initializes a new action client.
    /// - Parameters:
    ///   - requestTopic: The topic for the request.
    ///   - replyTopic: The topic for the reply.
    ///   - publisherSettings: A list of settings to apply to the request publisher.
    ///   - subscriberSettings: A list of settings to apply to the reply subscriber.
    /// - Throws: If the subscriber cannot be created.
    @inlinable
    public init(
        requestTopic: DDSTopic<Request>, replyTopic: DDSTopic<Reply>,
        publisherSettings: [DDSPublisher<Request>.Setting] = [], subscriberSettings: [DDSSubscriber<Reply>.Setting] = []
    ) throws(DDSError) {
        logger = Logger(label: "DDSActionClient(\(requestTopic.name), \(replyTopic.name))")

        logger.trace("Creating action client with request topic: \(requestTopic.name), and reply topic: \(replyTopic.name)")

        // Setup the reply content filter so that we only get replies that are related to our request
        Self.setupReplyFilter(logger: logger, topic: replyTopic)

        publisher = try requestTopic.publish(settings: publisherSettings + [.publishMode(.async)])
        subscriber = try replyTopic.subscribe(settings: subscriberSettings + [.enableFilter])

        subscriber.registerMessageCallback { [unowned self] message, metadata in
            activeActions.withLock { [unowned self] actions in
                guard let related = metadata.relatedIdentifier else {
                    logger.info("A message was recieved with no realated message identifier")
                    return
                }
                guard let continuation = actions[related] else {
                    logger.trace("A message was recieved with an unknown related message identifier")
                    return
                }
                actions.removeValue(forKey: related)

                continuation.resume(returning: message)
            }
        }
    }

    @usableFromInline
    internal static func setupReplyFilter(logger: Logger, topic: DDSTopic<Reply>) {
        // Try to register the content filter factory
        let ret = FastDDS.Actions.registerContentFilterFactory(&topic.participant.raw);
        if let error = FastDDSErrorCode.check(ret) {
            logger.warning("Failed to register content filter factory: \(error), falling back to normal topic")
            return
        }

        // Register the content filter if this doesn't work, we just use a normal topic
        let success = topic.raw.setContentFilter(
            name: .init("\(topic.name)_ActionReplyFiltered"),
            expression: " ",
            params: [],
            filter: FastDDS.Actions.getContentFilterName()
        )
        if !success {
            logger.warning("Failed to register content filter for \(self), falling back to normal topic")
        }
    }

    deinit {
        logger.trace("Destroying action client \(description)")
        subscriber.dataCallbacks.withLock { callbacks in
            callbacks.removeAll()
        }
    }
}

extension DDSActionClient {
    /// Sends a request to the action server and asynchronously waits for the reply.
    /// This can be cancelled by the caller.
    /// - Parameter request: The request to send.
    /// - Returns: The reply from the action server.
    /// - Throws: If the request cannot be sent.
    @inlinable
    public func send(request: borrowing Request) async throws(DDSError) -> Reply {
        logger.trace("Sending request")

        let identifier = try publisher.publishWithMetadata(request)

        let reply = await withTaskCancellationHandler {
            await withUnsafeContinuation { continuation in
                activeActions.withLock { actions in
                    actions[identifier] = continuation
                }
            }
        } onCancel: {
            activeActions.withLock { actions in
                if actions.keys.contains(identifier) {
                    actions.removeValue(forKey: identifier)
                }
            }
        }

        return reply
    }
}

extension DDSActionClient {
    /// The state of the action client.
    public enum State: Sendable {
        /// There are no servers.
        case none
        /// There is one server.
        case good
        /// There are too many servers.
        /// - Parameter Int: The number of servers.
        case tooMany(Int)
    }

    /// The state of the action client.
    public var state: State {
        if subscriber.publisherCount == 0 || publisher.subscriberCount == 0 {
            return .none
        } else if subscriber.publisherCount == 1 && publisher.subscriberCount == 1 {
            return .good
        } else {
            return .tooMany(max(subscriber.publisherCount, publisher.subscriberCount))
        }
    }

    /// Waits for a server to be ready.
    public func waitForServer() async {
        await subscriber.waitForPublisher()
        await publisher.waitForSubscriber()
    }
}

extension DDSActionClient where Reply: DDSActionResult /* This just means that it is a Result where both Failure and Success are DDSCodable */ {
    /// Sends a request to the action server and asynchronously waits for the reply.
    /// This can be cancelled by the caller.
    /// The reply is a Result, so it will be upacked into a success or it will throw a failure.
    /// - Parameter request: The request to send.
    /// - Returns: The reply from the action server if it is a success.
    /// - Throws: If the request cannot be sent. Or if the reply is a failure.
    @inlinable
    public func send(request: borrowing Request) async throws -> Reply.Success {
        try await send(request: request).get()
    }
}

extension DDSActionClient: CustomStringConvertible {
    public var description: String {
        "DDSActionClient(request: (\(publisher.topic.name), type: \(publisher.topic.typeName)), reply: (\(subscriber.topic.name), type: \(subscriber.topic.typeName)))"
    }
}

extension DDSParticipant {
    /// Creates a new action client on this participant.
    /// - Parameters:
    ///   - name: The base name of the topics used in the action.
    ///   - request: The message request data type.
    ///   - reply: The message reply data type.
    ///   - publisherSettings: A list of settings to apply to the request publisher.
    ///   - subscriberSettings: A list of settings to apply to the reply subscriber.
    ///   - convention: The naming convention to use for the action. If this is `.ros2`, the action will interop with ROS2 services.
    /// - Throws: If the subscriber cannot be created.
    public func createActionClient<Request: DDSMessage, Reply: DDSMessage>(
        name: String,
        request: Request.Type, reply: Reply.Type,
        publisherSettings: [DDSPublisher<Request>.Setting] = [], subscriberSettings: [DDSSubscriber<Reply>.Setting] = [],
        convention: DDSNamespace.NamingConvention = .default
    ) throws(DDSError) -> DDSActionClient<Request, Reply> {
        try DDSActionClient(
            participant: self,
            name: name,
            publisherSettings: publisherSettings, subscriberSettings: subscriberSettings,
            convention: convention
        )
    }
}
