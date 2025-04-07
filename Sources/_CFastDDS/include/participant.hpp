/*
 * participant.hpp
 * include
 * 
 * Created by Hunter Baker on 2/03/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <cstdint>
#include <fastdds/dds/core/detail/DDSReturnCode.hpp>
#include <fastdds/dds/log/Log.hpp>
#include <fastdds/rtps/attributes/RTPSParticipantAttributes.hpp>
#include <fastdds/rtps/common/Locator.hpp>
#include <fastdds/rtps/transport/TransportInterface.hpp>
#include <memory>
#include <string>

#if __has_include(<swift/bridging>)
# include <swift/bridging>
#else
# include "utils/swift_bridging.h"
#endif

#include "common.h"
#include "types/type_support.hpp"
#include "utils/guid.hpp"

#include <fastdds/dds/domain/DomainParticipant.hpp>
#include <fastdds/dds/domain/DomainParticipantFactory.hpp>
#include <fastdds/dds/domain/DomainParticipantListener.hpp>

#include <fastdds/utils/IPLocator.hpp>
#include <fastdds/rtps/common/LocatorList.hpp>
#include <fastdds/rtps/attributes/BuiltinTransports.hpp>
#include <fastdds/rtps/transport/network/NetmaskFilterKind.hpp>
#include <fastdds/rtps/transport/TransportDescriptorInterface.hpp>
#include <fastdds/rtps/transport/shared_mem/SharedMemTransportDescriptor.hpp>
#include <fastdds/rtps/transport/UDPv4TransportDescriptor.hpp>
#include <fastdds/rtps/transport/UDPv6TransportDescriptor.hpp>

class Publisher;
class Subscriber;
class Topic;

namespace FastDDS {

    using BuiltinTransports = eprosima::fastdds::rtps::BuiltinTransports;
    using NetmaskFilterKind = eprosima::fastdds::rtps::NetmaskFilterKind;
    using Locator = eprosima::fastdds::rtps::Locator_t;

    INLINE bool Locator_isIPV4(const std::string &address) {
        return eprosima::fastdds::rtps::IPLocator::isIPv4(address);
    }
    INLINE bool Locator_isIPV6(const std::string &address) {
        return eprosima::fastdds::rtps::IPLocator::isIPv6(address);
    }
    INLINE std::pair<bool, std::pair<bool, std::string>> Locator_lookupDNS(const std::string &name) {
        auto results = eprosima::fastdds::rtps::IPLocator::resolveNameDNS(name);

        if (!results.second.empty()) {
            return {/*success:*/true, {/*isIPv6:*/true, /*address:*/*results.second.begin()}};
        } else if (!results.first.empty()) {
            return {/*success:*/true, {/*isIPv6:*/false, /*address:*/*results.first.begin()}};
        } else {
            return {/*success:*/false, {}};
        }
    }
    INLINE void Locator_setIPV4(Locator &locator, const std::string &ipv4) {
        locator.kind = LOCATOR_KIND_UDPv4;
        eprosima::fastdds::rtps::IPLocator::setIPv4(locator, ipv4);
    }
    INLINE void Locator_setIPV6(Locator &locator, const std::string &ipv4) {
        locator.kind = LOCATOR_KIND_UDPv6;
        eprosima::fastdds::rtps::IPLocator::setIPv4(locator, ipv4);
    }

    class Participant final {
    public:
        using DomainParticipant = eprosima::fastdds::dds::DomainParticipant;
        using DomainParticipantFactory = eprosima::fastdds::dds::DomainParticipantFactory;
        using DomainParticipantQos = eprosima::fastdds::dds::DomainParticipantQos;
        using DomainID = eprosima::fastdds::dds::DomainId_t;
        using StatusMask = eprosima::fastdds::dds::StatusMask;

        using onParticipantDiscovery_t = void (^ SENDABLE _Nonnull)(const char * _Nonnull participantName);
        struct Callbacks {
            onParticipantDiscovery_t participantDiscoveryCallback;
        };

        class Qos final {
        public:
            INLINE Qos() {
                qos = DomainParticipantFactory::get_instance()->get_default_participant_qos();
            }
            INLINE Qos(std::string profile, eprosima::fastdds::dds::ReturnCode_t &ret) SWIFT_NAME(init(profileName:ret:)) : Qos() {
                ret = DomainParticipantFactory::get_instance()->get_participant_qos_from_profile(profile, qos);
            }

            INLINE void setName(const char * _Nonnull name) {
                qos.name(eprosima::fastcdr::string_255(name));
            }

            INLINE void setFilter(uint32_t flags, bool ignoreLocal) SWIFT_NAME(setFilter(flags:ignoreLocal:)) {
                qos.properties().properties().emplace_back("fastdds.ignore_local_endpoints", ignoreLocal ? "true" : "false");

                qos.wire_protocol().builtin.discovery_config.ignoreParticipantFlags = static_cast<eprosima::fastdds::rtps::ParticipantFilteringFlags>(flags);
            }

            INLINE void setMaxMessageSize(uint32_t size) {
                qos.properties().properties().emplace_back("fastdds.max_message_size", std::to_string(size));
            }

            INLINE void setTypePropagation(const std::string &mode) {
                qos.properties().properties().emplace_back("fastdds.type_propagation", mode);
            }

            INLINE void setEnabledStatistics(const std::string &names) {
                qos.properties().properties().emplace_back("fastdds.statistics", names);
            }
            
            INLINE void setPersistenceSqlite(const std::string &filename) {
                qos.properties().properties().emplace_back("dds.persistence.plugin", "builtin.SQLITE3");
                qos.properties().properties().emplace_back("dds.persistence.sqlite3.filename", filename);
            }

            INLINE void enableAuthentication(
                const std::string &identityCa, const std::string &identityCert, const std::string &identityCrl,
                const std::string &privateKey, const std::string &password, const std::string &preferredKeyAlgorithm
            ) SWIFT_NAME(enableAuthentication(identityCa:identityCert:identityCrl:privateKey:password:preferredKeyAlgorithm:)) {
                // enable authentication
                qos.properties().properties().emplace_back("dds.sec.auth.plugin", "builtin.PKI-DH");

                // setup identity
                qos.properties().properties().emplace_back("dds.sec.auth.builtin.PKI-DH.identity_ca", identityCa);
                qos.properties().properties().emplace_back("dds.sec.auth.builtin.PKI-DH.identity_certificate", identityCert);
                qos.properties().properties().emplace_back("dds.sec.auth.builtin.PKI-DH.private_key", privateKey);

                // optional parameters
                qos.properties().properties().emplace_back("dds.sec.auth.builtin.PKI-DH.identity_crl", identityCrl);
                qos.properties().properties().emplace_back("dds.sec.auth.builtin.PKI-DH.password", password);
                qos.properties().properties().emplace_back("dds.sec.auth.builtin.PKI-DH.prefered_key_algorithm", preferredKeyAlgorithm);
            }

            INLINE void enableAccessControl(
                const std::string &permissionsCa, const std::string &governance, const std::string &permissions
            ) SWIFT_NAME(enableAccessControl(permissionsCa:governance:permissions:)) {
                // enable access control
                qos.properties().properties().emplace_back("dds.sec.access.plugin", "builtin.Access-Permissions");

                // setup permissions
                qos.properties().properties().emplace_back("dds.sec.access.builtin.Access-Permissions.permissions_ca", permissionsCa);
                qos.properties().properties().emplace_back("dds.sec.access.builtin.Access-Permissions.governance", governance);
                qos.properties().properties().emplace_back("dds.sec.access.builtin.Access-Permissions.permissions", permissions);
            }

            INLINE void enableEncryption() {
                qos.properties().properties().emplace_back("dds.sec.crypto.plugin", "builtin.AES-GCM-GMAC");
            }

            INLINE void setBuiltinTransports(const BuiltinTransports &transports) {
                qos.setup_transports(transports);
                qos.transport().use_builtin_transports = transports != BuiltinTransports::NONE;
            }

            struct TransportCommonConfig {
                uint32_t maxMessageSize;
                uint32_t maxInitialPeersRange;
            };

            struct TransportNetworkSettings {
                uint32_t sendBufferSize;
                uint32_t receiveBufferSize;
                NetmaskFilterKind netmaskFilter;
                uint8_t timeToLive;
                bool nonBlockingSend;
                using AllowedInterfacesArray = std::vector<std::pair<std::string, NetmaskFilterKind>>; // Instantiate for Swift
                AllowedInterfacesArray allowedInterfaces;
                std::vector<std::string> blockedInterfaces;
            };
            
            INLINE void addUserTransportSHM(
                uint32_t segmentSize, uint32_t queueCapacity, uint32_t healthTimeout, TransportCommonConfig common
            ) SWIFT_NAME(addUserTransportSHM(segmentSize:queueCapacity:healthTimeout:common:)) {
                auto descriptor = std::make_shared<eprosima::fastdds::rtps::SharedMemTransportDescriptor>();

                if (segmentSize > 0) {
                    descriptor->segment_size(segmentSize);
                } else {
                    // Calculate a default segment size based on max message size and max samples per instance
                    descriptor->segment_size(
                        descriptor->max_message_size() * eprosima::fastdds::dds::DATAWRITER_QOS_DEFAULT.resource_limits().max_samples_per_instance
                    );
                }
                if (queueCapacity > 0) {
                    descriptor->port_queue_capacity(queueCapacity);
                }
                if (healthTimeout > 0) {
                    descriptor->healthy_check_timeout_ms(healthTimeout);
                }

                if (common.maxMessageSize > 0) {
                    descriptor->maxMessageSize = common.maxMessageSize;
                }
                if (common.maxInitialPeersRange > 0) {
                    descriptor->maxInitialPeersRange = common.maxInitialPeersRange;
                }

                qos.transport().user_transports.push_back(descriptor);
            }
            INLINE void addUserTransportUDPv4(
                uint16_t outPort, TransportCommonConfig common, TransportNetworkSettings settings
            ) SWIFT_NAME(addUserTransportUDPv4(outPort:common:networkSettings:)) {
                auto descriptor = std::make_shared<eprosima::fastdds::rtps::UDPv4TransportDescriptor>();

                descriptor->m_output_udp_socket = outPort;

                descriptor->sendBufferSize = settings.sendBufferSize;
                descriptor->receiveBufferSize = settings.receiveBufferSize;
                descriptor->TTL = settings.timeToLive;
                descriptor->non_blocking_send = settings.nonBlockingSend;
                for (auto &allowedInterface : settings.allowedInterfaces) {
                    descriptor->interface_allowlist.emplace_back(allowedInterface.first, allowedInterface.second);
                }
                for (auto &blockedInterface : settings.blockedInterfaces) {
                    descriptor->interface_blocklist.emplace_back(blockedInterface);
                }

                if (common.maxMessageSize > 0) {
                    descriptor->maxMessageSize = common.maxMessageSize;
                }
                if (common.maxInitialPeersRange > 0) {
                    descriptor->maxInitialPeersRange = common.maxInitialPeersRange;
                }

                qos.transport().user_transports.push_back(descriptor);
            }
            INLINE void addUserTransportUDPv6(
                uint16_t outPort, TransportCommonConfig common, TransportNetworkSettings settings
            ) SWIFT_NAME(addUserTransportUDPv6(outPort:common:networkSettings:)) {
                auto descriptor = std::make_shared<eprosima::fastdds::rtps::UDPv6TransportDescriptor>();

                descriptor->m_output_udp_socket = outPort;

                descriptor->sendBufferSize = settings.sendBufferSize;
                descriptor->receiveBufferSize = settings.receiveBufferSize;
                descriptor->TTL = settings.timeToLive;
                descriptor->non_blocking_send = settings.nonBlockingSend;
                for (auto &allowedInterface : settings.allowedInterfaces) {
                    descriptor->interface_allowlist.emplace_back(allowedInterface.first, allowedInterface.second);
                }
                for (auto &blockedInterface : settings.blockedInterfaces) {
                    descriptor->interface_blocklist.emplace_back(blockedInterface);
                }

                if (common.maxMessageSize > 0) {
                    descriptor->maxMessageSize = common.maxMessageSize;
                }
                if (common.maxInitialPeersRange > 0) {
                    descriptor->maxInitialPeersRange = common.maxInitialPeersRange;
                }

                qos.transport().user_transports.push_back(descriptor);
            }
            INLINE void addUserTransportCustom(void * _Nonnull rawDescriptor) SWIFT_NAME(addUserTransportCustom(descriptor:)) {
                auto descriptor = *(std::shared_ptr<eprosima::fastdds::rtps::TransportDescriptorInterface> *)(rawDescriptor);
                qos.transport().user_transports.push_back(descriptor);
            }

            INLINE void setDiscoveryModeSIMPLE(bool readOnly, bool writeOnly) SWIFT_NAME(setDiscoveryModeSIMPLE(readOnly:writeOnly:)) {
                qos.wire_protocol().builtin.discovery_config.use_SIMPLE_EndpointDiscoveryProtocol = true;
                qos.wire_protocol().builtin.discovery_config.use_STATIC_EndpointDiscoveryProtocol = false;
                qos.wire_protocol().builtin.discovery_config.discoveryProtocol = eprosima::fastdds::rtps::DiscoveryProtocol::SIMPLE;

                qos.wire_protocol().builtin.discovery_config.m_simpleEDP.use_PublicationWriterANDSubscriptionReader = !readOnly;
                qos.wire_protocol().builtin.discovery_config.m_simpleEDP.use_PublicationReaderANDSubscriptionWriter = !writeOnly;
            }
            NODISCARD INLINE bool setDiscoveryModeSTATIC(const std::string &configFile) {
                auto ret = getFactory()->check_xml_static_discovery(const_cast<std::string &>(configFile));
                if (ret != eprosima::fastdds::dds::RETCODE_OK) {
                    return false;
                }

                qos.wire_protocol().builtin.discovery_config.use_SIMPLE_EndpointDiscoveryProtocol = false;
                qos.wire_protocol().builtin.discovery_config.use_STATIC_EndpointDiscoveryProtocol = true;
                qos.wire_protocol().builtin.discovery_config.discoveryProtocol = eprosima::fastdds::rtps::DiscoveryProtocol::SIMPLE; // There is no STATIC for this

                return true;
            }
            INLINE void setDiscoveryModeSERVER(const std::vector<Locator> &servers, const std::vector<Locator> &metatrafficLocators) {
                qos.wire_protocol().builtin.discovery_config.discoveryProtocol = eprosima::fastdds::rtps::DiscoveryProtocol::SERVER;
                for (auto &locator : servers) {
                    qos.wire_protocol().builtin.discovery_config.m_DiscoveryServers.push_back(locator);
                }
                for (auto &locator : metatrafficLocators) {
                    qos.wire_protocol().builtin.metatrafficUnicastLocatorList.push_back(locator);
                }
            }
            INLINE void setDiscoveryModeBACKUP(const std::vector<Locator> &servers, const std::vector<Locator> &metatrafficLocators) {
                qos.wire_protocol().builtin.discovery_config.discoveryProtocol = eprosima::fastdds::rtps::DiscoveryProtocol::BACKUP;
                for (auto &locator : servers) {
                    qos.wire_protocol().builtin.discovery_config.m_DiscoveryServers.push_back(locator);
                }
                for (auto &locator : metatrafficLocators) {
                    qos.wire_protocol().builtin.metatrafficUnicastLocatorList.push_back(locator);
                }
            }
            INLINE void setDiscoveryModeCLIENT(const std::vector<Locator> &servers) {
                qos.wire_protocol().builtin.discovery_config.discoveryProtocol = eprosima::fastdds::rtps::DiscoveryProtocol::CLIENT;
                for (auto &locator : servers) {
                    qos.wire_protocol().builtin.discovery_config.m_DiscoveryServers.push_back(locator);
                }
            }
            INLINE void disableDiscoveryMulticast() {
                qos.wire_protocol().builtin.metatrafficMulticastLocatorList.clear();
                Locator locator; // Empty locator
                qos.wire_protocol().builtin.metatrafficMulticastLocatorList.push_back(locator);
            }
            INLINE void setDiscoveryInitialPeers(const std::vector<Locator> &peers) {
                for (auto &peer : peers) {
                    qos.wire_protocol().builtin.initialPeersList.push_back(peer);
                }
            }

            INLINE const DomainParticipantQos &get() const {
                return qos;
            }

        private:
            DomainParticipantQos qos;
        };

        INLINE Participant(DomainID domainId, const Qos &qos, bool &success) SWIFT_NAME(init(domain:profile:success:)) {
            participant = getFactory()->create_participant(domainId, qos.get(), nullptr, StatusMask::none());
            success = participant != nullptr;
            destroyed = !success;

            auto publisherQos = participant->get_default_subscriber_qos();
            publisherQos.entity_factory().autoenable_created_entities = false;
            if (participant->set_default_subscriber_qos(publisherQos) != eprosima::fastdds::dds::RETCODE_OK) {
                EPROSIMA_LOG_WARNING(Participant, "Failed to set publisher QoS");
                success = false;
                static_cast<void>(destroy());
            }

            auto subscriberQos = participant->get_default_subscriber_qos();
            subscriberQos.entity_factory().autoenable_created_entities = false;
            if (participant->set_default_subscriber_qos(subscriberQos) != eprosima::fastdds::dds::RETCODE_OK) {
                EPROSIMA_LOG_WARNING(Participant, "Failed to set publisher QoS");
                success = false;
                static_cast<void>(destroy());
            }
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t setGuidPrefixHostInfo(uint16_t hostInfo) SWIFT_NAME(setGuidPrefix(hostInfo:)) {
            auto qos = participant->get_qos();
            qos.wire_protocol().prefix = participant->guid().guidPrefix;
            qos.wire_protocol().prefix.value[2] = hostInfo & 0xFF;
            qos.wire_protocol().prefix.value[3] = (hostInfo >> 8) & 0xFF;
            return participant->set_qos(qos);
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t setGuidPrefix(const GUIDPrefix &guidPrefix) SWIFT_NAME(setGuidPrefix(prefix:)) {
            auto qos = participant->get_qos();
            qos.wire_protocol().prefix = guidPrefix;
            return participant->set_qos(qos);
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t enable() {
            return participant->enable();
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t setCallbacks(const Callbacks &callbacks) {
            listener = std::make_unique<Listener>(callbacks);
            return participant->set_listener(listener.get(), StatusMask::none());
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t destroy() {
            auto listenerRet = participant->set_listener(nullptr, StatusMask::none());
            if (!destroyed) {
                auto ret = participant->delete_contained_entities();
                if (ret != eprosima::fastdds::dds::RETCODE_OK) { return ret; }

                ret = getFactory()->delete_participant(participant);
                if (ret != eprosima::fastdds::dds::RETCODE_OK) { return ret; }

                destroyed = true;
            }
            listener = nullptr;
            return listenerRet;
        }
        INLINE bool getDestroyed() const SWIFT_COMPUTED_PROPERTY {
            return destroyed;
        }

        INLINE GUID getGuid() const SWIFT_COMPUTED_PROPERTY {
            return participant->guid();
        }

        INLINE DomainID getDomain() const SWIFT_COMPUTED_PROPERTY {
            return participant->get_domain_id();
        }

        INLINE const char * _Nonnull getName() const SWIFT_COMPUTED_PROPERTY {
            return participant->get_qos().name().c_str();
        }

        INLINE std::vector<std::string> getParticipants() const SWIFT_COMPUTED_PROPERTY {
            return participant->get_participant_names();
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t registerDataType(const Types::TypeSupport &typeSupportWrapper) SWIFT_NAME(registerType(typeSupport:)) {
            return participant->register_type(typeSupportWrapper.typeSupport);
        }

        // NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t unregisterDataType(const TypeSupportWrapper &typeSupportWrapper) SWIFT_NAME(unregisterType(typeSupport:)) {
        //     return participant->unregister_type(typeSupportWrapper.typeSupport.get_type_name());
        // }

        INLINE void updateNetworkInterfaces() {
            auto qos = participant->get_qos();
            (void) participant->set_qos(qos); // This should never fail because I didn't change any qos values. This somehow magically updates the network interfaces.
        }

        INLINE void * _Nonnull getNative() const SWIFT_COMPUTED_PROPERTY {
            return participant;
        }

        INLINE DomainParticipant * _Nonnull getParticipant() const {
            return participant;
        }

    private:
        static INLINE DomainParticipantFactory * _Nonnull getFactory() {
            return DomainParticipantFactory::get_instance();
        }

        class Listener final : public eprosima::fastdds::dds::DomainParticipantListener {
        public:
            explicit Listener(const Callbacks &callbacks);
            ~Listener() override;

            // Non-copyable because it would deallocate the blocks
            Listener( const Listener& ) = delete;
            Listener& operator=( const Listener& ) = delete;

            void on_participant_discovery(
                DomainParticipant * _Nullable participant,
                eprosima::fastdds::rtps::ParticipantDiscoveryStatus reason,
                const eprosima::fastdds::dds::ParticipantBuiltinTopicData &info,
                bool &should_be_ignored
            ) override;

#ifdef HAVE_SECURITY
            void onParticipantAuthentication(
                DomainParticipant * _Nullable participant,
                eprosima::fastdds::rtps::ParticipantAuthenticationInfo &&info
            ) override;
#endif
        private:
            onParticipantDiscovery_t participantDiscoveryCallback;
        };

        DomainParticipant * _Nonnull participant;
        std::unique_ptr<Listener> listener;

        bool destroyed = false;

        friend class Publisher;
        friend class Subscriber;
        friend class Topic;
    } SWIFT_NONCOPYABLE SENDABLE;

} 
