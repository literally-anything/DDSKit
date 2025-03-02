/**
 * Transports.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 3/01/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

/// Defines the transport type that will be used by a DDS participant.
public enum DDSTransport {
    /// Some common configuration parameters that are used by all transport types.
    /// - Note: These values are doumented here: https://fast-dds.docs.eprosima.com/en/latest/fastdds/transport/transport_api.html#data-members
    public struct CommonConfig {
        /// Maximum size of a single message in the transport.
        var maxMessageSize: UInt32
        /// Number of channels opened with each initial remote peer.
        var maxInitialPeersRange: UInt32

        /// Initializes a new instance of the `CommonConfig` struct.
        /// - Parameters:
        ///   - maxMessageSize: 
        ///   - maxInitialPeersRange: 
        public init(maxMessageSize: UInt32 = 0, maxInitialPeersRange: UInt32 = 0) {
            self.maxMessageSize = maxMessageSize
            self.maxInitialPeersRange = maxInitialPeersRange
        }
    }

    /// Some common network and socket configuration parameters that are used by multiple transport types.
    public struct NetworkSettings {
        /// Size of the send buffer. Defaults to to a system defined value.
        var sendBufferSize: UInt32
        /// Size of the receive buffer. Defaults to to a system defined value.
        var receiveBufferSize: UInt32
        /// Time to live for the socket in number of hops. Defaults to auto.
        var netmaskFilter: Bool?
        /// Time to live for the socket in number of hops. Defaults to 1.
        var timeToLive: UInt8
        /// Whether the socket is non-blocking. Defaults to `false`.
        /// - Note: Setting this to `true` will mean that if the buffer is full, the message will be dropped instead of blocking the sender until there is space.
        var nonBlockingSend: Bool
        /// A dictionary of allowed interfaces and whether the netmask filter should be enabled.\
        /// If the value is `nil`, this defaults to the `netmaskFilter` property of `SocketSettings`.
        /// If this is empty, all interfaces are allowed except those in the `blockedInterfaces` list.
        var allowedInterfaces: [String: Bool?]
        /// A list of blocked interfaces.
        /// This overrides the `allowedInterfaces` list.
        var blockedInterfaces: [String]

        /// Initializes a new instance of the `SocketSizes` struct.
        /// - Parameters:
        ///   - sendBufferSize: Size of the send buffer.
        ///   - receiveBufferSize: Size of the receive buffer.
        ///   - timeToLive: Time to live for the socket in number of hops.
        ///   - nonBlockingSend: Whether the socket is non-blocking. This means that a message will be dropped if the buffer is full instead of waiting for space.
        ///   - allowedInterfaces: A list of allowed interfaces. Allows all if left empty.
        ///   - blockedInterfaces: A list of blocked interfaces.
        public init(
            sendBufferSize: UInt32 = 0, receiveBufferSize: UInt32 = 0, netmaskFilter: Bool? = nil, timeToLive: UInt8 = 1, nonBlockingSend: Bool = false,
            allowedInterfaces: [String] = [], blockedInterfaces: [String] = []
        ) {
            self.sendBufferSize = sendBufferSize
            self.receiveBufferSize = receiveBufferSize
            self.netmaskFilter = netmaskFilter
            self.timeToLive = timeToLive
            self.nonBlockingSend = nonBlockingSend
            self.allowedInterfaces = .init(uniqueKeysWithValues: allowedInterfaces.map { ($0, nil) })
            self.blockedInterfaces = blockedInterfaces
        }

        /// Initializes a new instance of the `SocketSizes` struct.
        /// - Parameters:
        ///   - sendBufferSize: Size of the send buffer.
        ///   - receiveBufferSize: Size of the receive buffer.
        ///   - timeToLive: Time to live for the socket in number of hops.
        ///   - nonBlockingSend: Whether the socket is non-blocking. This means that a message will be dropped if the buffer is full instead of waiting for space.
        ///   - allowedInterfaces: A dictionary of allowed interfaces and whether the netmask filter should be enabled. Allows all if left empty.
        ///   - blockedInterfaces: A list of blocked interfaces.
        @_disfavoredOverload
        public init(
            sendBufferSize: UInt32 = 0, receiveBufferSize: UInt32 = 0, netmaskFilter: Bool? = nil, timeToLive: UInt8 = 1, nonBlockingSend: Bool = false,
            allowedInterfaces: [String: Bool?] = [:], blockedInterfaces: [String] = []
        ) {
            self.sendBufferSize = sendBufferSize
            self.receiveBufferSize = receiveBufferSize
            self.netmaskFilter = netmaskFilter
            self.timeToLive = timeToLive
            self.nonBlockingSend = nonBlockingSend
            self.allowedInterfaces = allowedInterfaces
            self.blockedInterfaces = blockedInterfaces
        }
    }


    /// Defines a shared memory transport.
    /// All parameters are optional.
    /// - Parameters:
    ///   - segmentSize: The size of the shared memory segment in bytes.
    ///   - queueCapacity: The capacity of the listening port in messages.
    ///   - healthTimeout: The timeout in milliseconds for the health check.
    ///   - common: Common configuration parameters.
    /// - Note: This page explains what each parameter does: https://fast-dds.docs.eprosima.com/en/latest/fastdds/transport/shared_memory/shared_memory.html
    case sharedMemory(
        segmentSize: UInt32 = 0, queueCapacity: UInt32 = 0, healthTimeout: UInt32 = 0,
        common: CommonConfig = .init()
    )
    /// Defines a shared memory transport.
    public var sharedMemory: Self { .sharedMemory() }

    /// Defines a UDPv4 transport.
    /// All parameters are optional.
    /// - Parameters:
    ///   - outPort: The port for outgoing messages. 0 means default.
    ///   - common: Common configuration parameters.
    ///   - networkSettings: Network and socket configuration parameters.
    /// - Note: This page explains what each parameter does: https://fast-dds.docs.eprosima.com/en/latest/fastdds/transport/udp/udp.html
    case udp4(
        outPort: UInt16 = 0,
        common: CommonConfig = .init(), setworkSettings: NetworkSettings = .init()
    )
    /// Defines a UDPv4 transport.
    public var udp4: Self { .udp4() }
    /// Defines a UDPv4 transport.
    public var udp: Self { .udp4() }

    /// Defines a UDPv6 transport.
    /// All parameters are optional.
    /// - Parameters:
    ///   - outPort: The port for outgoing messages. 0 means default.
    ///   - common: Common configuration parameters.
    ///   - networkSettings: Network and socket configuration parameters.
    /// - Note: This page explains what each parameter does: https://fast-dds.docs.eprosima.com/en/latest/fastdds/transport/udp/udp.html
    case udp6(
        outPort: UInt16 = 0,
        common: CommonConfig = .init(), setworkSettings: NetworkSettings = .init()
    )
    /// Defines a UDPv6 transport.
    public var udpv6: Self { .udp6() }

    // /// Defines a TCPv4 transport.
    // /// All parameters are optional.
    // /// - Parameters:
    // ///   - listeningPorts: The ports to listen on. Empty or 0 means auto assigned.
    // ///   - keepAliveFrequency: The frequency of the keep alive in milliseconds.
    // ///   - keepAliveTimeout: The time to wait after the last keep alive before assuming that the connection is dead in milliseconds.
    // ///   - tcpNoDelay: Whether to disable Nagle's algorithm (set TCP_NODELAY on the socket).
    // ///   - common: Common configuration parameters.
    // ///   - networkSettings: Network and socket configuration parameters.
    // /// - Note: This page explains what each parameter does: https://fast-dds.docs.eprosima.com/en/latest/fastdds/transport/tcp/tcp.html
    // case tcp4(
    //     listeningPorts: [UInt16] = [], keepAliveFrequency: UInt32 = 0, keepAliveTimeout: UInt32 = 0, tcpNoDelay: Bool = false,
    //     common: CommonConfig = .init(), setworkSettings: NetworkSettings = .init()
    // )
    // /// Defines a TCPv4 transport.
    // public var tcp4: Self { .tcp4() }
    // /// Defines a TCPv4 transport.
    // public var tcp: Self { .tcp4() }

    // /// Defines a TCPv6 transport.
    // /// All parameters are optional.
    // /// - Parameters:
    // ///     - listeningPorts: The ports to listen on. Empty or 0 means auto assigned.
    // ///     - keepAliveFrequency: The frequency of the keep alive in milliseconds.
    // ///     - keepAliveTimeout: The time to wait after the last keep alive before assuming that the connection is dead in milliseconds.
    // ///     - tcpNoDelay: Whether to disable Nagle's algorithm (set TCP_NODELAY on the socket).
    // ///     - common: Common configuration parameters.
    // ///     - networkSettings: Network and socket configuration parameters.
    // /// - Note: This page explains what each parameter does: https://fast-dds.docs.eprosima.com/en/latest/fastdds/transport/tcp/tcp.html
    // case tcp6(
    //     listeningPorts: [UInt16] = [], keepAliveFrequency: UInt32 = 0, keepAliveTimeout: UInt32 = 0, tcpNoDelay: Bool = false,
    //     common: CommonConfig = .init(), setworkSettings: NetworkSettings = .init()
    // )
    // /// Defines a TCPv6 transport.
    // public var tcp6: Self { .tcp6() }

    /// Defines a custom transport.
    /// - Parameter descriptor: A pointer to the shared pointer to the custom transport descriptor.
    case custom(descriptor: OpaquePointer)
}

extension FastDDS.NetmaskFilterKind {
    internal init(_ kind: Bool?) {
        switch kind {
            case true:
                self = .ON
            case false:
                self = .OFF
            default:
                self = .AUTO
        }
    }
}

extension FastDDS.Participant.Qos.TransportCommonConfig {
    internal init(_ config: DDSTransport.CommonConfig) {
        self.init(maxMessageSize: config.maxMessageSize, maxInitialPeersRange: config.maxInitialPeersRange)
    }
}

extension FastDDS.Participant.Qos.TransportNetworkSettings {
    internal init(_ config: DDSTransport.NetworkSettings) {
        var allowedInterfacesConverted: FastDDS.Participant.Qos.TransportNetworkSettings.AllowedInterfacesArray = []
        for (key, value) in config.allowedInterfaces {
            allowedInterfacesConverted.push_back(.init(first: std.string(key), second: .init(value)))
        }
        self.init(
            sendBufferSize: config.sendBufferSize, receiveBufferSize: config.receiveBufferSize,
            netmaskFilter: .init(config.netmaskFilter), timeToLive: config.timeToLive, nonBlockingSend: config.nonBlockingSend,
            allowedInterfaces: allowedInterfacesConverted,
            blockedInterfaces: .init(config.blockedInterfaces.map { std.string($0) })
        )
    }
}
