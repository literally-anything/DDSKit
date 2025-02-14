/*
 * participant.hpp
 * include
 * 
 * Created by Hunter Baker on 2/03/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <fastcdr/cdr/fixed_size_string.hpp>
#include <memory>
#include <swift/bridging>

#include "common.h"
#include "GenericTopicType.hpp"
#include "swift_helpers.hpp"

#include <fastdds/dds/log/Log.hpp>
#include <fastdds/dds/core/status/StatusMask.hpp>
#include <fastdds/dds/domain/DomainParticipant.hpp>
#include <fastdds/dds/domain/DomainParticipantFactory.hpp>
#include <fastdds/dds/domain/DomainParticipantListener.hpp>
#include <fastdds/dds/domain/qos/DomainParticipantQos.hpp>
#include <fastdds/dds/builtin/topic/ParticipantBuiltinTopicData.hpp>

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

        static INLINE DomainParticipantQos getDefaultQos() SWIFT_COMPUTED_PROPERTY {
            return DomainParticipantFactory::get_instance()->get_default_participant_qos();
        }

        INLINE Participant(
            DomainID domainId, const std::string &profileName, _FastDDSHelpers::ParticipantCallbacks * _Nonnull callbacks, const StatusMask &statusMask, bool &success
        ) SWIFT_NAME(init(domain:profile:callbacks:statusMask:success:)) : listener(std::make_unique<Listener>(callbacks)) {
            participant = getFactory()->create_participant_with_profile(domainId, profileName, listener.get(), statusMask);
            success = participant != nullptr;
        }

        INLINE Participant(
            DomainID domainId, const DomainParticipantQos &qos, _FastDDSHelpers::ParticipantCallbacks * _Nonnull callbacks, const StatusMask &statusMask, bool &success
        ) SWIFT_NAME(init(domain:profile:callbacks:statusMask:success:)) : listener(std::make_unique<Listener>(callbacks)) {
            participant = getFactory()->create_participant(domainId, qos, listener.get(), statusMask);
            success = participant != nullptr;
        }

        INLINE eprosima::fastdds::dds::ReturnCode_t destroy() {
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

        INLINE StatusMask getStatusMask() const SWIFT_COMPUTED_PROPERTY {
            return participant->get_status_mask();
        }
        INLINE void setStatusMask(const StatusMask &mask) SWIFT_COMPUTED_PROPERTY {
            participant->set_listener(listener.get(), mask);
        }

        INLINE DomainParticipantQos getQos() const SWIFT_COMPUTED_PROPERTY {
            return participant->get_qos();
        }
        INLINE void setQos(const DomainParticipantQos &qos) SWIFT_COMPUTED_PROPERTY {
            if (participant->set_qos(qos) != eprosima::fastdds::dds::RETCODE_OK) {
                EPROSIMA_LOG_WARNING(Participant, "Failed to set QoS");
            }
        }

        INLINE eprosima::fastdds::dds::ReturnCode_t registerDataType(const TypeSupportWrapper &typeSupportWrapper) SWIFT_NAME(registerType(typeSupport:)) {
            return participant->register_type(typeSupportWrapper.typeSupport);
        }

        INLINE eprosima::fastdds::dds::ReturnCode_t unregisterDataType(const TypeSupportWrapper &typeSupportWrapper) SWIFT_NAME(unregisterType(typeSupport:)) {
            return participant->unregister_type(typeSupportWrapper.typeSupport.get_type_name());
        }

    private:
        static INLINE DomainParticipantFactory * _Nonnull getFactory() {
            return DomainParticipantFactory::get_instance();
        }

        class Listener final : public eprosima::fastdds::dds::DomainParticipantListener {
        public:
            INLINE explicit Listener(_FastDDSHelpers::ParticipantCallbacks * _Nonnull callbacks) : callbacks(callbacks) {}

            void on_participant_discovery(
                DomainParticipant * _Nullable participant,
                eprosima::fastdds::rtps::ParticipantDiscoveryStatus reason,
                const eprosima::fastdds::dds::ParticipantBuiltinTopicData &info,
                bool &should_be_ignored
            ) override;

        private:
            _FastDDSHelpers::ParticipantCallbacks * _Nonnull callbacks;
        };

        DomainParticipant * _Nonnull participant;
        std::unique_ptr<Listener> listener;

        bool destroyed = false;

        friend class Publisher;
        friend class Subscriber;
        friend class Topic;
    } SWIFT_NONCOPYABLE;

} 
