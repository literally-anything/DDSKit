/**
 * SocketAddress.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 3/02/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import _CFastDDS

/// A socket address.
/// This is a combination of an IP address and a port number.
public struct SocketAddress {
    public enum Address {
        case ipv4(String)
        case ipv6(String)
    }

    /// The IP address.
    public var address: Address
    /// The port number.
    public var port: UInt16

    /// Creates a new IPv4 socket address.
    /// - Parameters:
    ///   - address: The IPv4 address.
    ///   - port: The port number.
    public init(ipv4 address: String, port: UInt16) {
        self.address = .ipv4(address)
        self.port = port
    }

    /// Creates a new IPv6 socket address.
    /// - Parameters:
    ///   - address: The IPv6 address.
    ///   - port: The port number.
    public init(ipv6 address: String, port: UInt16) {
        self.address = .ipv6(address)
        self.port = port
    }

    /// The FastDDS locator for this socket address.
    internal var locator: FastDDS.Locator {
        var locator = FastDDS.Locator(.init(port))
        switch address {
            case .ipv4(let address):
                FastDDS.Locator_setIPV4(&locator, .init(address))
            case .ipv6(let address):
                FastDDS.Locator_setIPV6(&locator, .init(address))
        }
        return locator
    }
}
