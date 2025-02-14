/*
 * participant.cpp
 * src
 * 
 * Created by Hunter Baker on 2/12/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#include "participant.hpp"

void Participant::Listener::on_participant_discovery(
    DomainParticipant *participant,
    eprosima::fastdds::rtps::ParticipantDiscoveryStatus reason,
    const eprosima::fastdds::dds::ParticipantBuiltinTopicData &info,
    bool &should_be_ignored
) {
    callbacks->participantDiscovered(participant, &reason, &info);
}
