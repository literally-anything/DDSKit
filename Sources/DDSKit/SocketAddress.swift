/**
 * SocketAddress.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 3/02/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
public import IP
internal import _CFastDDS

/// A socket address.
/// This is a combination of an IP address and a port number.
public struct SocketAddress {
    /// The IP address.
    public var address: any IP.Address
    /// The port number.
    public var port: UInt16

    /// Creates a new socket address.
    /// - Parameters:
    ///   - address: The IP address.
    ///   - port: The port number.
    public init(address: any IP.Address, port: UInt16) {
        self.address = address
        self.port = port
    }

    /// The FastDDS locator for this socket address.
    internal var locator: FastDDS.Locator {
        var locator = FastDDS.Locator(.init(port))
        if address is IP.V4 {
            FastDDS.Locator_setIPV4(&locator, .init(address.description))
        } else {
            FastDDS.Locator_setIPV6(&locator, .init(address.description))
        }
        return locator
    }
}
