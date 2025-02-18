/*
 * participant.hpp
 * include
 * 
 * Created by Hunter Baker on 2/03/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <mutex>
#include <memory>
#include <string>
#include <swift/bridging>

#include "common.h"
#include "GenericTopicType.hpp"

#include <fastdds/dds/log/Log.hpp>
#include <fastdds/rtps/common/Guid.hpp>
#include <fastdds/dds/core/status/StatusMask.hpp>
#include <fastdds/dds/domain/DomainParticipant.hpp>
#include <fastdds/dds/domain/DomainParticipantFactory.hpp>
#include <fastdds/dds/domain/qos/DomainParticipantFactoryQos.hpp>
#include <fastdds/dds/domain/DomainParticipantListener.hpp>
#include <fastdds/dds/domain/qos/DomainParticipantQos.hpp>
#include <fastcdr/cdr/fixed_size_string.hpp>

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

        static INLINE DomainParticipantQos getDefaultQos() SWIFT_COMPUTED_PROPERTY {
            return DomainParticipantFactory::get_instance()->get_default_participant_qos();
        }

        INLINE Participant(
            DomainID domainId, const std::string &profileName, bool &success
        ) SWIFT_NAME(init(domain:profile:success:)) {
            participant = getFactory()->create_participant_with_profile(domainId, profileName, nullptr, StatusMask::none());
            success = participant != nullptr;
            destroyed = !success;
        }

        INLINE Participant(DomainID domainId, DomainParticipantQos qos, bool &success) SWIFT_NAME(init(domain:profile:success:)) {
            qos.entity_factory().autoenable_created_entities = false;

            participant = getFactory()->create_participant(domainId, qos, nullptr, StatusMask::none());
            success = participant != nullptr;
            destroyed = !success;
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t enable() {
            return participant->enable();
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t setCallbacks(const Callbacks &callbacks) {
            listener = std::make_unique<Listener>(callbacks);
            return participant->set_listener(listener.get(), StatusMask::none());
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t destroy() {
            if (!destroyed) {
                auto ret = participant->delete_contained_entities();
                if (ret != eprosima::fastdds::dds::RETCODE_OK) { return ret; }

                ret = getFactory()->delete_participant(participant);
                if (ret != eprosima::fastdds::dds::RETCODE_OK) { return ret; }

                destroyed = true;
            }
            return eprosima::fastdds::dds::RETCODE_OK;
        }
        INLINE bool getDestroyed() const SWIFT_COMPUTED_PROPERTY {
            return destroyed;
        }

        INLINE DomainID getDomain() const SWIFT_COMPUTED_PROPERTY {
            return participant->get_domain_id();
        }

        INLINE const char * _Nonnull getName() const SWIFT_COMPUTED_PROPERTY {
            return participant->get_qos().name().c_str();
        }

        INLINE DomainParticipantQos getQos() const SWIFT_COMPUTED_PROPERTY {
            return participant->get_qos();
        }
        INLINE void setQos(const DomainParticipantQos &qos) SWIFT_COMPUTED_PROPERTY {
            if (participant->set_qos(qos) != eprosima::fastdds::dds::RETCODE_OK) {
                EPROSIMA_LOG_WARNING(Participant, "Failed to set QoS");
            }
        }

        INLINE std::vector<std::string> getParticipants() const SWIFT_COMPUTED_PROPERTY {
            return participant->get_participant_names();
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t registerDataType(const TypeSupportWrapper &typeSupportWrapper) SWIFT_NAME(registerType(typeSupport:)) {
            return participant->register_type(typeSupportWrapper.typeSupport);
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t unregisterDataType(const TypeSupportWrapper &typeSupportWrapper) SWIFT_NAME(unregisterType(typeSupport:)) {
            return participant->unregister_type(typeSupportWrapper.typeSupport.get_type_name());
        }

    private:
        static INLINE DomainParticipantFactory * _Nonnull getFactory() {
            static std::mutex mutex;
            std::lock_guard<std::mutex> lock(mutex);

            static bool qos_done = false;
            if (!qos_done) {
                eprosima::fastdds::dds::DomainParticipantFactoryQos qos;
                DomainParticipantFactory::get_instance()->get_qos(qos);

                qos.entity_factory().autoenable_created_entities = false;

                if (DomainParticipantFactory::get_instance()->set_qos(qos) != eprosima::fastdds::dds::RETCODE_OK) {
                    EPROSIMA_LOG_WARNING(Participant, "Failed to set participant factory QoS");
                }

                qos_done = true;
            }

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
    } SWIFT_NONCOPYABLE;

} 
