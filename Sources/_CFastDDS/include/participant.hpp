/*
 * participant.hpp
 * include
 * 
 * Created by Hunter Baker on 2/03/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <cstdint>
#include <string>

#if __has_include(<swift/bridging>)
# include <swift/bridging>
#else
# include "utils/swift_bridging.h"
#endif

#include "common.h"
#include "cdr/type_support.hpp"
#include "utils/guid.hpp"

#include <fastdds/dds/domain/DomainParticipant.hpp>
#include <fastdds/dds/domain/DomainParticipantFactory.hpp>
#include <fastdds/dds/domain/DomainParticipantListener.hpp>

class Publisher;
class Subscriber;
class Topic;

namespace FastDDS {

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

            INLINE void setName(const char * _Nonnull name) {
                qos.name(eprosima::fastcdr::string_255(name));
            }

            INLINE void setIgnoreLocalEndpoints(bool ignore) {
                qos.properties().properties().emplace_back("fastdds.ignore_local_endpoints", ignore ? "true" : "false");
            }

            INLINE void setMaxMessageSize(uint32_t size) {
                qos.properties().properties().emplace_back("fastdds.max_message_size", std::to_string(size));
            }
            INLINE void setMaxMessageSizeToMinTransportSize() {
                // qos.properties().properties().emplace_back("fastdds.max_message_size", std::to_string(size));
            }

            INLINE void setTypePropagationEnabled() {
                qos.properties().properties().emplace_back("fastdds.type_propagation", "enabled");
            }
            INLINE void setTypePropagationDisabled() {
                qos.properties().properties().emplace_back("fastdds.type_propagation", "disabled");
            }
            INLINE void setTypePropagationMinimal() {
                qos.properties().properties().emplace_back("fastdds.type_propagation", "minimal_bandwidth");
            }
            INLINE void setTypePropagationRegistrationOnly() {
                qos.properties().properties().emplace_back("fastdds.type_propagation", "registration_only");
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

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t registerDataType(const TypeSupportWrapper &typeSupportWrapper) SWIFT_NAME(registerType(typeSupport:)) {
            return participant->register_type(typeSupportWrapper.typeSupport);
        }

        // NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t unregisterDataType(const TypeSupportWrapper &typeSupportWrapper) SWIFT_NAME(unregisterType(typeSupport:)) {
        //     return participant->unregister_type(typeSupportWrapper.typeSupport.get_type_name());
        // }

        INLINE void * _Nonnull getNative() const SWIFT_COMPUTED_PROPERTY {
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
