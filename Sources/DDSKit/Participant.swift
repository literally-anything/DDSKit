/**
 * Participant.swift
 * DDSKit
 * 
 * Created by Hunter Baker on 2/03/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
internal import Synchronization
internal import Logging
internal import _CFastDDS

/// A participant in the DDS network.
///
/// A participant is the main entry point for all DDS communication.
/// Particiants are linked to a specific domain and can only communicate with other participants in the same domain.
/// Participants can create topics with publishers and subscribers which send and receive messages.
public final class DDSParticipant: @unchecked Sendable {
    /// The logger for the participant.
    internal let logger: Logger

    /// A wrapper around the underlying FastDDS DomainParticipant.
    /// The wrapper is needed because the FastDDS DomainParticipant is mostly virtual and fails to import into swift.
    internal var raw: FastDDS.Participant

    /// A wrapper around the underlying FastDDS Publisher.
    /// This is not a DDSPublisher! It is a FastDDS Publisher which allows you to allocate DataWriters.
    /// The wrapper is needed because the FastDDS Publisher is mostly virtual and fails to import into swift.
    internal var rawPublisher: FastDDS.Publisher

    /// A wrapper around the underlying FastDDS Subscriber.
    /// This is not a DDSSubscriber! It is a FastDDS Subscriber which allows you to allocate DataReaders.
    /// The wrapper is needed because the FastDDS Subscriber is mostly virtual and fails to import into swift.
    internal var rawSubscriber: FastDDS.Subscriber

    /// A list of callbacks to call when a new participant is detected.
    /// The callback is passed the name of the detected participant.
    /// The callback will be automatically removed if it returns true. (This is needed because callbacks are not Equatable)
    private let detectionCallbacks: Mutex<[@Sendable (String) -> Bool]> = Mutex([])

    /// Initializes a new DDSParticipant.
    /// - Parameters:
    ///   - domain: The domain id for the participant. Only other participants in the same domain can communicate with each other. Defaults to 0.
    ///   - name: The user-defined name for the participant. Defaults to the name of the function that intialized the participant.
    ///   - settings: An optional list of settings for the participant.
    /// - Throws: DDSError if the participant fails to initialize.
    public init(domain: UInt32 = 0, name: String = DDSNamespace.current.appending(relative: #function).description, settings: [Setting] = []) throws(DDSError) {
        /// In C++, this is represented as a fixed-size string, so it must be less than 256 characters.
        assert(name.count < 256, "Name must be less than 256 characters")

        // Setup the library wrapper. (Only happens on the first successful call)
        try FastDDSSetup.setup()

        logger = Logger(
            label: "DDSKit.Participant",
            metadataProvider: .init {
                [
                    "domain": "\(domain)",
                    "name": "\(name)"
                ]
            }
        )

        var qos = FastDDS.Participant.Qos()

        name.withCString { cString in
            qos.setName(cString)
        }

        let postSetup: (inout FastDDS.Participant, borrowing Logger) throws(DDSError) -> Void
        do throws(DDSError.ConfigurationError) {
            postSetup = try Self.parseSettings(settings: settings, qos: &qos, logger: logger)
        } catch let error {
            throw .configuration(error)
        }

        var success = false

        raw = FastDDS.Participant(
            domain: domain,
            profile: qos,
            success: &success
        )
        guard success else {
            throw DDSError.initializationError(from: .participant)
        }

        try postSetup(&raw, logger)

        // If this isn't enabled before creating the publisher and subscriber, it segfaults when creating a reader or witer.
        try FastDDSErrorCode.checkThrow(raw.enable(), from: .participant)

        rawPublisher = FastDDS.Publisher(
            participant: raw, 
            // profile: FastDDS.Publisher.Qos(participant: raw),
            success: &success
        )
        guard success else {
            try FastDDSErrorCode.checkThrowInternal(raw.destroy(), from: .participant)
            throw DDSError.initializationError(from: .publisher)
        }

        rawSubscriber = FastDDS.Subscriber(
            participant: raw,
            // profile: FastDDS.Subscriber.Qos(participant: raw),
            success: &success
        )
        guard success else {
            try FastDDSErrorCode.checkThrowInternal(raw.destroy(), from: .participant)
            throw DDSError.initializationError(from: .subscriber)
        }

        // If something fails, destroy the participant to not leak memory.
        var setupDone = false
        defer {
            if !setupDone {
                try! FastDDSErrorCode.checkThrowInternal(raw.destroy(), from: .participant)
            }
        }

        try FastDDSErrorCode.checkThrowInternal(
            raw.setCallbacks(.init { [unowned self] participantNameC in
                // Called when new participant is discovered
                detectionCallbacks.withLock { callbacks in
                    guard !callbacks.isEmpty else {
                        return
                    }

                    let name = String(cString: participantNameC)

                    // This is reversed so that we can remove elements from the array while iterating
                    for (index, callback) in callbacks.enumerated().reversed() {
                        // Remove the callback if it returns true
                        if callback(name) {
                            callbacks.remove(at: index)
                        }
                    }
                }
            }),
            from: .participant
        )

        try FastDDSErrorCode.checkThrow(rawPublisher.enable(), from: .publisher)
        try FastDDSErrorCode.checkThrow(rawSubscriber.enable(), from: .subscriber)

        setupDone = true
    }

    deinit {
        // Publisher and Subscriber are destroyed by the Participant's destroy function
        let ret = FastDDSErrorCode.check(raw.destroy())
        if let ret {
            let error = DDSError.destructionError(
                from: .participant,
                ret
            )
            fatalError("\(error)")
        }
    }

    /// The domain id of the participant.
    /// Only other participants in the same domain can communicate with each other.
    public var domain: UInt32 {
        raw.domain
    }

    /// The user-defined name of the participant.
    public var name: String {
        String(cString: raw.name)
    }
}

extension DDSParticipant {
    /// The entity identifier of the participant.
    public var identifier: DDSEntityIdentifier {
        DDSEntityIdentifier(guid: raw.guid)
    }

    /// A list of the other participants' names on the same domain.
    public var participants: [String] {
        raw.participants.map { cxxString in
            String(cxxString)
        }
    }

    /// Waits for a participant to join the domain.
    /// Will return immediately if the specified participant is already in the domain.
    /// - Parameter name: The name of the participant to wait for.
    public func waitForParticipant(named name: String) async {
        assert(name != self.name, "Cannot wait for self")

        // Check if the participant is already in the domain
        guard !participants.contains(name) else {
            return
        }

        await withUnsafeContinuation { continuation in
            detectionCallbacks.withLock { callbacks in
                callbacks.append { participantName in
                    guard participantName == name else {
                        return false
                    }
                    continuation.resume()
                    return true
                }
            }
        }
    }
}

extension DDSParticipant {
    /// Registers a type with the participant.
    /// This shouldn't be called directly. Instead, DDSTopic should call it in it's initializer.
    /// - Parameter type: The type to register.
    /// - Throws: DDSTypeError if the type fails to register.
    internal func registerType(typeSupport: DDSTypeSupport) throws(DDSTypeError) {
        let error = FastDDSErrorCode.check(raw.registerType(typeSupport: typeSupport.typeSupport))

        if let error {
            switch error {
                // Returned when the type name is size 0
                case .badParameter:
                    throw .invalidName
                // Returned when the type name is already registered
                case .preconditionFailed:
                    throw .alreadyRegistered
                default:
                    assertionFailure("Got unexpected return code when registering FastDDS type: \(error)")
            }
        }
    }
}

extension DDSParticipant {
    /// A setting for the participant.
    /// If multiple settings of the same type are provided, the last one will be used unless otherwise specified.
    public enum Setting {
        /// Loads a profile with the specified name from an XML file.
        /// This will be loaded before applying any other settings, and only the last one will be used.
        /// These are documented in the FastDDS documentation: https://fast-dds.docs.eprosima.com/en/latest/fastdds/xml_configuration/xml_configuration.html
        /// - Warning: This is not recommended because there are many settings that aren't accounted for in this library, and messing with them can cause undefined behavior.
        /// - Parameter name: The name of the profile to load.
        case loadProfile(name: String)

        /// Sets whether to ingnore DataReaders and DataWriters that are created from the same participant.
        /// Defaults to false.
        case ignoreLocalEndpoints(Bool)

        /// Sets the method to use to get the entity identifier prefix for the participant.
        /// This matters because the prefix is used to identify the process and host of the participant for data-sharing and intra-process delivery.
        /// This defalts to `.internallyAssigned`, which uses the default guid prefix in fastdds.
        case identiferPrefixMethod(IdentifierPrefixMethod)

        /// The maximum size of a message that can be sent or received.
        /// Defaults to 4294967295 if no value is provided.
        case maxMessageSize(UInt32)

        /// Sets mode to use to propagate data types to other participants.
        /// This shoild really only need to be changed if you are very bandwidth constrained.
        /// Defaults to `.enabled`.
        case typePropagation(TypePropagationMode)

        /// Sets the mode to use for discovery.
        /// Defaults to `.simple`.
        case discovery(DiscoveryMode)

        /// Sets the transports to use for the participant and all children.
        /// Defaults to just the default built-in transport: `.default`.
        /// If this is provided multiple times, all of the custom transports will be used, but only the last built-in transport will be used.
        /// If custom transports are provided, the built-in transports will be disabled, unless built-in transports are also explicitly provided.
        case transports(Transports)

        /// Enables the specified statistics module topics.
        /// The names are documented in the FastDDS documentation: https://fast-dds.docs.eprosima.com/en/latest/fastdds/statistics/dds_layer/topic_names.html#statistics-topic-names
        /// This stacks if multiple settings are provided.
        case statistics([String])

        /// Sets the persistence plugin to use for the participant.
        /// The last one will be used if multiple are provided.
        /// `nil` is the default and means that persistence is disabled.
        case persistence(PersistencePlugin?)

        /// Enables and configures the authentication plugin for the participant.
        /// The last setting to be applied will be used.
        /// - Parameters:
        ///   - identityCA: The path to the identity CA certificate.
        ///   - identityCertificate: The path to the signed identity certificate.
        ///   - privateKey: The path to the private key. This can either be a file path or a PKCS#11 URL (which is stored on the HSM).
        ///   - password: The password to decrypt the private key. This is optional and will be ignored if the private key is a PKCS#11 URL.
        ///   - identityCrl: The path to a CRL (Certificate Revocation List). This is optional.
        ///   - prefferedKeyAlgorithm: The preferred key algorithm to use. If this is not provided, this will decided automatically.
        case authentication(
            identityCA: String, identityCertificate: String,
            privateKey: String, password: String? = nil,
            identityCrl: String? = nil, prefferedKeyAlgorithm: AuthenticationPreferedKeyAlgorithm? = nil
        )

        /// Enables and configures the access control plugin for the participant.
        /// The last setting to be applied will be used.
        /// - Parameters:
        ///   - permissionsCA: The path to the permissions CA certificate.
        ///   - governance: The path to the governance file in S/MIME format signed by the permissions CA.
        ///   - permissions: The path to the permissions file in S/MIME format signed by the permissions CA.
        case accessControl(
            permissionsCA: String,
            governance: String, permissions: String
        )

        /// The method to use to get the entity identifier prefix for the participant.
        /// This matters because the prefix is used to identify the process and host of the participant for data-sharing and intra-process delivery.
        public enum IdentifierPrefixMethod {
            /// The prefix is assigned internally by fastdds.
            /// - Warning: This is sometimes an issue because it uses information about network interfaces. If network intefaces change at runtime, don't use this.
            /// This is the default.
            case internallyAssigned
            /// Uses more unique information about the host to ensure that data-sharing works even if network interfaces change.
            case hostUnique
            /// The prefix is assigned by the user.
            /// - Note: The fastdds documentation says which bytes are used for what, so follow this or data-sharing and intra-process delivery will not work.
            case userAssigned(DDSEntityIdentifier.Prefix)
        }

        /// The mode to use to propagate data types to other participants.
        public enum TypePropagationMode {
            /// Propagate all data type info to other participants.
            case enabled
            /// Do not propagate data type info to other participants.
            case disabled
            /// Use the minimum bandwidth possible to propagate data type info to other participants.
            case minimal
            /// Only send data type info to other participants, do not receive it.
            case registrationOnly
        }

        /// The mode to use for discovery.
        /// How this works is documented in the FastDDS documentation: https://fast-dds.docs.eprosima.com/en/latest/fastdds/discovery/discovery.html
        public enum DiscoveryMode {
            /// Use the SIMPLE discovery mode.
            /// 
            /// This is the default mode, and is the simplest to use.
            /// 
            /// The Participant Discovery Phase (PDP) will identify the participants in the network using multicast (default) or unicast.
            /// The Endpoint Discovery Phase (EDP) will identify the publishers and subscribers of each participant.
            /// This mode allows for very simple configuration and is very robust, but it increases the network traffic and setup time.
            /// 
            /// To only use unicast for discovery, set `enableMulticast` to false, and add every participant's address to `initialPeers`.
            /// `initialPeers` can also be used with multicast enabled in situations where multicast is not possible or unreliable (for example, on WiFi).
            /// 
            /// If there are multiple discovery mode settings, the last one will be used, but the `initialPeers` will be combined.
            /// 
            /// - Parameters:
            ///   - enableMulticast: Whether to enable multicast for discovery. Defaults to true.
            ///   - initialPeers: The initial peers to connect to. This allows for participants to be discovered through unicast. Defaults to an empty array.
            case simple(enableMulticast: Bool = true, initialPeers: [SocketAddress] = [])
            /// Use the STATIC discovery mode.
            /// 
            /// The Participant Discovery Phase (PDP) will identify the participants in the network using multicast (default) or unicast.
            /// But, the Endpoint Discovery Phase (EDP) is not used. This means that 
            // case `static`()

            //case discoveryServer
        }

        /// The transports to use for the participant and all children.
        /// - Note: If defined using an array literal, this does not include the built-in transports.
        public enum Transports: ExpressibleByArrayLiteral {
            /// Configure built-in transports for IPv4.
            /// Use the built-in transports. By default, this is UDPv4 and Shared Memory.
            /// This can be changed using the `FASTDDS_BUILTIN_TRANSPORTS` environment variable.
            /// This is the default.
            case `default`
            /// Configure built-in transports for IPv6.
            /// By default, this is UDPv6 and Shared Memory.
            /// This can be changed using the `FASTDDS_BUILTIN_TRANSPORTS` environment variable.
            case defaultv6
            /// Configure built-in transports for large ammounts of data over IPv4.
            /// By default, this is UDPv4, TCPv4, and Shared Memory, but UDPv4 is only used for bootstrapping discovery.
            /// This can be changed using the `FASTDDS_BUILTIN_TRANSPORTS` environment variable.
            case largeData
            /// Configure built-in transports for large ammounts of data over IPv6.
            /// Use the built-in transports. By default, this is UDPv6, TCPv6, and Shared Memory, but UDPv6 is only used for bootstrapping discovery.
            /// This can be changed using the `FASTDDS_BUILTIN_TRANSPORTS` environment variable.
            case largeDatav6

            /// Use the specified transports.
            /// - Note: This will disable the built-in transports, unless a built-in transport is also explicitly enabled so you must specify every transport you want to use.
            /// - Parameter transports: The transports to use.
            case custom(_ transports: [DDSTransport])

            /// Creates a new Transports from an array literal.
            /// This does not include the built-in transports.
            /// - Parameter elements: The transports to use.
            public init(arrayLiteral elements: DDSTransport...) {
                self = .custom(elements)
            }
        }

        /// The persistence plugin to use for the participant.
        public enum PersistencePlugin {
            /// Use sqlite3 for persistence.
            /// - Parameter filename: The name of the sqlite3 file to use for persistence.
            case sqlite3(filename: String)
        }

        /// The preffered key algorithm to use for authentication.
        public enum AuthenticationPreferedKeyAlgorithm: String {
            /// The DH key algorithm (Diffie-Hellman Ephemeral with 2048-bit MODP Group parameters).
            case dh = "DH+MODP-2048-256"
            /// The ECDH key algorithm (Elliptic Curve Diffie-Hellman Ephemeral with the NIST P-256 curve).
            case ecdh = "ECDH+prime256v1-CEUM"
        }
    }

    /// Parses the settings and applies them to the qos.
    /// - Parameters:
    ///   - settings: The settings to parse.
    ///   - qos: The qos to apply the settings to.
    ///   - logger: The logger to use for logging.
    /// - Returns: A post-setup function that will be called after the participant is created.
    /// - Throws: DDSError if a loadProfile setting fails to load.
    private static func parseSettings(
        settings: [Setting], qos: inout FastDDS.Participant.Qos, logger: borrowing Logger
    ) throws(DDSError.ConfigurationError) -> (inout FastDDS.Participant, borrowing Logger) throws(DDSError) -> Void {
        guard !settings.isEmpty else {
            return { _, _ in }
        }

        // The name of the XML profile to load.
        var profileName: String?
        // Whether to ignore local participants.
        var ignoreLocalEndpoints: Bool?
        // The method to use to get the entity identifier prefix for the participant.
        // This matters because the prefix is used to identify the process and host of the participant for data-sharing and intra-process delivery.
        var identifierPrefixMethod: Setting.IdentifierPrefixMethod = .internallyAssigned
        // The maximum size of a message that can be sent or received.
        var maxMessageSize: UInt32?
        // The mode to use to propagate data types to other participants.
        var typePropagationMode: Setting.TypePropagationMode?
        // The mode to use for discovery.
        var discoveryMode: Setting.DiscoveryMode?
        // The built-in transports mode and the user-defined transports.
        var builtinTransportsMode: FastDDS.BuiltinTransports = .NONE
        var userTransports: [DDSTransport] = []
        // The enabled statistics module topics.
        var enabledStatistics: [String] = []
        // The persistence plugin to use for the participant.
        var persistencePlugin: Setting.PersistencePlugin?
        // The authentication settings to use for the participant.
        var authenticationSettings: (ca: String, cert: String, key: String, pass: String?, crl: String?, keyAlgorithm: String?)? = nil
        // The access control settings to use for the participant.
        var accessControlSettings: (ca: String, governance: String, permissions: String)? = nil

        for setting in settings {
            switch setting {
                case .loadProfile(let name): profileName = name
                case .ignoreLocalEndpoints(let ignore): ignoreLocalEndpoints = ignore
                case .identiferPrefixMethod(let method): identifierPrefixMethod = method
                case .maxMessageSize(let size): maxMessageSize = size
                case .typePropagation(let mode): typePropagationMode = mode
                case .discovery(let mode): discoveryMode = mode
                case .transports(let transports):
                    switch transports {
                        case .default:
                            builtinTransportsMode = .DEFAULT
                        case .defaultv6:
                            builtinTransportsMode = .DEFAULTv6
                        case .largeData:
                            builtinTransportsMode = .LARGE_DATA
                        case .largeDatav6:
                            builtinTransportsMode = .LARGE_DATAv6
                        case .custom(let customTransports):
                            userTransports.append(contentsOf: customTransports)
                    }
                case .statistics(let names): enabledStatistics += names
                case .persistence(let plugin): persistencePlugin = plugin
                case .authentication(
                    let identityCA, let identityCertificate,
                    let privateKey, let password,
                    let identityCrl, let prefferedKeyAlgorithm
                ):
                    authenticationSettings = (identityCA, identityCertificate, privateKey, password, identityCrl, prefferedKeyAlgorithm?.rawValue)
                case .accessControl(let permissionsCA, let governance, let permissions):
                    accessControlSettings = (permissionsCA, governance, permissions)
            }
        }

        // Load the profile if it was specified.
        if let profileName {
            var ret: Int32 = 0
            qos = .init(profileName: .init(profileName), ret: &ret)
            if let error = FastDDSErrorCode.check(ret) {
                throw .profile(name: profileName, error)
            }
        }

        // Set the ignore local endpoints setting.
        if let ignoreLocalEndpoints {
            qos.setIgnoreLocalEndpoints(ignoreLocalEndpoints)
        }

        // Set the maximum message size.
        if let maxMessageSize {
            qos.setMaxMessageSize(maxMessageSize)
        }

        // Set the type propagation mode.
        if let typePropagationMode {
            switch typePropagationMode {
                case .enabled:
                    qos.setTypePropagation("enabled")
                case .disabled:
                    qos.setTypePropagation("disabled")
                case .minimal:
                    qos.setTypePropagation("minimal_bandwidth")
                case .registrationOnly:
                    qos.setTypePropagation("registration_only")
            }
        }

        // Set the discovery mode.
        if let discoveryMode {
            switch discoveryMode {
                case .simple(let enableMulticast, let initialPeers):
                    qos.setDiscoveryModeSIMPLE()
                    qos.setDiscoveryMulticast(enableMulticast)
                    qos.setDiscoveryInitialPeers(.init(initialPeers.map { $0.locator }))
            }
        }

        // If there are no user transports, we use the built-in transports, but otherwise we only use built-in transports if they are explicitly enabled.
        if userTransports.isEmpty {
            builtinTransportsMode = .DEFAULT
        }
        qos.setBuiltinTransports(builtinTransportsMode)
        for transport in userTransports {
            switch transport {
                case .sharedMemory(let segmentSize, let queueCapacity, let healthTimeout, let common):
                    qos.addUserTransportSHM(segmentSize: segmentSize, queueCapacity: queueCapacity, healthTimeout: healthTimeout, common: .init(common))
                case .udp4(let outPort, let common, let networkSettings):
                    qos.addUserTransportUDPv4(outPort: outPort, common: .init(common), networkSettings: .init(networkSettings))
                case .udp6(let outPort, let common, let networkSettings):
                    qos.addUserTransportUDPv6(outPort: outPort, common: .init(common), networkSettings: .init(networkSettings))
                case .custom(let descriptor):
                    qos.addUserTransportCustom(descriptor: .init(descriptor))
            }
        }

        // Setup statistics.
        if !enabledStatistics.isEmpty {
            // Statistics are a comma separated list of enabled statistics topics.
            qos.setEnabledStatistics(.init(enabledStatistics.joined(separator: ";")))
        }

        // Set the persistence plugin.
        if let persistencePlugin {
            switch persistencePlugin {
                case .sqlite3(let filename):
                    qos.setPersistenceSqlite(.init(filename))
            }
        }

        // Setup the authentication plugin.
        if let authenticationSettings {
            qos.enableAuthentication(
                identityCa: .init(authenticationSettings.ca),
                identityCert: .init(authenticationSettings.cert),
                identityCrl: .init(authenticationSettings.crl ?? ""),
                privateKey: .init(authenticationSettings.key),
                password: .init(authenticationSettings.pass ?? ""),
                preferredKeyAlgorithm: .init(authenticationSettings.keyAlgorithm ?? "")
            )
        }

        // Setup the access control plugin.
        if let accessControlSettings {
            qos.enableAccessControl(
                permissionsCa: .init(accessControlSettings.ca),
                governance: .init(accessControlSettings.governance),
                permissions: .init(accessControlSettings.permissions)
            )
        }

        return { participant, logger throws(DDSError) in
            // Set after creating the participant but before enabling, so the base of the GUID will be generated, but can still be modified.
            switch identifierPrefixMethod {
                case .internallyAssigned: break // Nothing to do here, this is the default
                case .hostUnique:
                    let hostIdentifier = FastDDS.getMachineId()
                    #if DEBUG
                        // When debugging, check that the host identifier doesn't change between calls to passively ensure that this mechanism works.
                        struct MachineIDDebug { static let uniqueId: Mutex<UInt16?> = .init(nil) }
                        MachineIDDebug.uniqueId.withLock { uniqueId in
                            if uniqueId == nil {
                                uniqueId = hostIdentifier
                            } else {
                                assert(uniqueId == hostIdentifier, "Host identifier changed between calls")
                            }
                        }
                    #endif
                    guard hostIdentifier != 0 else {
                        logger.warning("Failed to get host identifier, falling back to .internallyAssigned prefix")
                        break
                    }
                    try FastDDSErrorCode.checkThrowInternal(participant.setGuidPrefix(hostInfo: hostIdentifier))
                case .userAssigned(let userPrefix):
                    try FastDDSErrorCode.checkThrowInternal(participant.setGuidPrefix(prefix: userPrefix.guidPrefix))
            }
        }
    }
}

extension DDSParticipant {
    /// Sets whether intra-process delivery is enabled for all participants.
    /// This is a global setting that affects all participants in the process.
    /// - Note: When this is enabled, all participants in the same process will communicate without going through the transport layer. This means that the subscriber callback will be called directly by the caller of the publish method.
    /// - Parameter enabled: Whether intra-process delivery is enabled.
    public static func setIntraProcessDelivery(enabled: Bool) {
        FastDDS.setIntraProcessDelivery(enabled: enabled)
    }
}

extension DDSParticipant: CustomStringConvertible {
    public var description: String {
        "DDSParticipant(domain: \(domain), name: \(name))"
    }
}
