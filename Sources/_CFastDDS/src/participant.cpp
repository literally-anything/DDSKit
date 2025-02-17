/*
 * participant.cpp
 * src
 * 
 * Created by Hunter Baker on 2/12/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#include "participant.hpp"

#include <../lib/swift/Block/Block.h>

#include <fastdds/rtps/participant/ParticipantDiscoveryInfo.hpp>
#include <fastdds/dds/builtin/topic/ParticipantBuiltinTopicData.hpp>

using namespace eprosima::fastdds::dds;
using namespace eprosima::fastdds::rtps;

namespace FastDDS {

    Participant::Listener::Listener(const Callbacks &callbacks) {
        participantDiscoveryCallback = Block_copy(callbacks.participantDiscoveryCallback);
    }

    Participant::Listener::~Listener() {
        Block_release(participantDiscoveryCallback);
    }

    void Participant::Listener::on_participant_discovery(
        DomainParticipant *participant,
        ParticipantDiscoveryStatus reason,
        const ParticipantBuiltinTopicData &info,
        bool &should_be_ignored
    ) {
        if (participant->guid() != info.guid) {
            if (reason == ParticipantDiscoveryStatus::DISCOVERED_PARTICIPANT) {
                participantDiscoveryCallback(info.participant_name.c_str());
            }
        }
    }

#ifdef HAVE_SECURITY
    void Participant::Listener::onParticipantAuthentication(
        DomainParticipant *participant,
        ParticipantAuthenticationInfo &&info
    ) {}
#endif

}
