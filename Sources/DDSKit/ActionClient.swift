/**
 * ActionClient.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 1/23/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import Synchronization
internal import Logging

public final class DDSActionClient<Request: DDSCodable, Reply: DDSCodable>: Sendable {
    private let logger: Logger
    private let publisher: DDSPublisher<Request>
    private let subscriber: DDSSubscriber<Reply>
    private let activeActions: Mutex<[MessageIdentifier: UnsafeContinuation<Reply, Never>]> = Mutex([:])

    public convenience init(
        participant: DDSParticipant, name actionName: String,
        publisherSettings: [DDSPublisher<Request>.Setting] = [], subscriberSettings: [DDSSubscriber<Reply>.Setting] = []
    ) throws(DDSError) {
        let (requestTopic, replyTopic) = getActionTopicNames(base: actionName)

        // Needs publish mode async because, when using intra-process communication, the publisher and subscriber are on the same thread.
        self.init(
            requestPublisher: try participant.publish(to: requestTopic, type: Request.self, settings: publisherSettings + [.publishMode(.async)]),
            replySubscriber: try participant.subscribe(to: replyTopic, type: Reply.self, settings: subscriberSettings)
        )
    }

    public convenience init(
        requestTopic: DDSTopic<Request>, replyTopic: DDSTopic<Reply>,
        publisherSettings: [DDSPublisher<Request>.Setting] = [], subscriberSettings: [DDSSubscriber<Reply>.Setting] = []
    ) throws(DDSError) {
        self.init(
            requestPublisher: try requestTopic.publish(settings: publisherSettings + [.publishMode(.async)]),
            replySubscriber: try replyTopic.subscribe(settings: subscriberSettings)
        )
    }

    public init(requestPublisher: DDSPublisher<Request>, replySubscriber: DDSSubscriber<Reply>) {
        logger = Logger(label: "DDSActionClient(\(requestPublisher.topic.name), \(replySubscriber.topic.name))")

        publisher = requestPublisher
        subscriber = replySubscriber

        subscriber.registerMessageCallback { [unowned self] message, indentifiers in
            activeActions.withLock { [unowned self] actions in
                guard let related = indentifiers.related else {
                    logger.warning("A message was recieved with no realated message identifier")
                    return
                }
                guard let continuation = actions[related] else {
                    logger.warning("A message was recieved with an unknown related message identifier")
                    return
                }
                actions.removeValue(forKey: related)

                continuation.resume(returning: message)
            }
        }
    }

    deinit {
        subscriber.dataCallbacks.withLock { callbacks in
            callbacks.removeAll()
        }
    }
}

extension DDSActionClient {
    public func send(request: borrowing Request) async throws(DDSError) -> Reply {
        let identifier = try publisher.publishWithIdentifiers(request, related: nil)

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
    public enum State: Sendable {
        case none
        case good
        case tooMany(Int)
    }

    public var state: State {
        if subscriber.publisherCount == 0 || publisher.subscriberCount == 0 {
            return .none
        } else if subscriber.publisherCount == 1 && publisher.subscriberCount == 1 {
            return .good
        } else {
            return .tooMany(max(subscriber.publisherCount, publisher.subscriberCount))
        }
    }

    public func waitForServer() async {
        await subscriber.waitForPublisher()
        await publisher.waitForSubscriber()
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
    /// - Throws: If the subscriber cannot be created.
    public func createActionClient<Request: DDSCodable, Reply: DDSCodable>(
        name: String,
        request: Request.Type, reply: Reply.Type,
        publisherSettings: [DDSPublisher<Request>.Setting] = [], subscriberSettings: [DDSSubscriber<Reply>.Setting] = []
    ) throws(DDSError) -> DDSActionClient<Request, Reply> {
        try DDSActionClient(
            participant: self,
            name: name,
            publisherSettings: publisherSettings, subscriberSettings: subscriberSettings
        )
    }
}
