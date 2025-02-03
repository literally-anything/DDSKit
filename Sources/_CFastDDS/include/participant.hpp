/*
 * participant.hpp
 * include
 * 
 * Created by Hunter Baker on 2/03/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <fastdds/dds/builtin/topic/ParticipantBuiltinTopicData.hpp>
#include <fastdds/dds/core/status/StatusMask.hpp>
#include <swift/bridging>

#include "common.h"
#include "swift_helpers.hpp"

#include <fastdds/dds/domain/DomainParticipant.hpp>
#include <fastdds/dds/domain/DomainParticipantFactory.hpp>
#include <fastdds/dds/domain/DomainParticipantListener.hpp>
#include <fastdds/dds/domain/qos/DomainParticipantQos.hpp>

class Participant final {
public:
    using DomainParticipant = eprosima::fastdds::dds::DomainParticipant;
    using DomainParticipantFactory = eprosima::fastdds::dds::DomainParticipantFactory;
    using DomainParticipantQos = eprosima::fastdds::dds::DomainParticipantQos;
    using DomainID = eprosima::fastdds::dds::DomainId_t;
    using StatusMask = eprosima::fastdds::dds::StatusMask;

    INLINE Participant() : listener(nullptr) {
        participant = getFactory()->create_participant_with_default_profile();
        participant->set_listener(&listener);
    }

    INLINE Participant(
        DomainID domainId, const std::string &profileName, _FastDDSHelpers::ParticipantCallbacks *callbacks, const StatusMask &statusMask
    ) SWIFT_NAME(init(domain:profile:callbacks:statusMask:)) : listener(nullptr) {
        listener.callbacks = callbacks;
        participant = getFactory()->create_participant_with_profile(domainId, profileName, &listener, statusMask);
    }

    INLINE Participant(
        DomainID domainId, const DomainParticipantQos &qos, _FastDDSHelpers::ParticipantCallbacks *callbacks, const StatusMask &statusMask
    ) SWIFT_NAME(init(domain:profile:callbacks:statusMask:)) : listener(nullptr) {
        listener.callbacks = callbacks;
        participant = getFactory()->create_participant(domainId, qos, &listener, statusMask);
    }

    INLINE DomainID getDomain() const SWIFT_COMPUTED_PROPERTY {
        return participant->get_domain_id();
    }

    INLINE StatusMask getStatusMask() const SWIFT_COMPUTED_PROPERTY {
        return participant->get_status_mask();
    }
    INLINE void setStatusMask(const StatusMask &mask) SWIFT_COMPUTED_PROPERTY {
        participant->set_listener(&listener, mask);
    }

    INLINE DomainParticipantQos getQos() const SWIFT_COMPUTED_PROPERTY {
        return participant->get_qos();
    }
    INLINE void setQos(const DomainParticipantQos &qos) SWIFT_COMPUTED_PROPERTY {
        participant->set_qos(qos);
    }

private:
    class Listener final : public eprosima::fastdds::dds::DomainParticipantListener {
    public:
        _FastDDSHelpers::ParticipantCallbacks *callbacks;

        INLINE explicit Listener(_FastDDSHelpers::ParticipantCallbacks *callbacks) : callbacks(callbacks) {}
        INLINE void on_participant_discovery(
            DomainParticipant *participant,
            eprosima::fastdds::rtps::ParticipantDiscoveryStatus reason,
            const eprosima::fastdds::dds::ParticipantBuiltinTopicData &info,
            bool &should_be_ignored
        ) {
            callbacks->participantDiscovered(participant, &reason, &info);
        }
    };

    Listener listener;
    DomainParticipant *participant;

    static INLINE DomainParticipantFactory *getFactory() {
        return DomainParticipantFactory::get_instance();
    }
};
