/*
 * publisher.hpp
 * src
 * 
 * Created by Hunter Baker on 2/03/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <swift/bridging>

#include "common.h"
#include "participant.hpp"
#include "swift_helpers.hpp"

#include <fastdds/dds/log/Log.hpp>
#include <fastdds/dds/core/status/StatusMask.hpp>
#include <fastdds/dds/publisher/Publisher.hpp>
#include <fastdds/dds/publisher/qos/PublisherQos.hpp>

class DataWriter;

namespace FastDDS {

    class Publisher final {
    public:
        using _Publisher = eprosima::fastdds::dds::Publisher;
        using PublisherQos = eprosima::fastdds::dds::PublisherQos;
        using StatusMask = eprosima::fastdds::dds::StatusMask;

        static INLINE PublisherQos getDefaultQos(const Participant &participantWrapper) SWIFT_NAME(getDefaultQos(participant:)) {
            return participantWrapper.participant->get_default_publisher_qos();
        }

        INLINE Publisher(
            const Participant &participantWrapper, const std::string &profileName, bool &success
        ) SWIFT_NAME(init(participant:profile:success:)) : participant(participantWrapper.participant) {
            publisher = participant->create_publisher_with_profile(profileName, nullptr, StatusMask::none());
            success = publisher != nullptr;
        }

        INLINE Publisher(
            const Participant &participantWrapper, const PublisherQos &qos, bool &success
        ) SWIFT_NAME(init(participant:profile:success:)) : participant(participantWrapper.participant) {
            publisher = participant->create_publisher(qos, nullptr, StatusMask::none());
            success = publisher != nullptr;
        }

        INLINE eprosima::fastdds::dds::ReturnCode_t destroy() {
            if (!destroyed) {
                auto ret = publisher->delete_contained_entities();
                if (ret != eprosima::fastdds::dds::RETCODE_OK) { return ret; }

                ret = participant->delete_publisher(publisher);
                if (ret != eprosima::fastdds::dds::RETCODE_OK) { return ret; }

                destroyed = true;
            }
            return eprosima::fastdds::dds::RETCODE_OK;
        }
        INLINE bool getDestroyed() const SWIFT_COMPUTED_PROPERTY {
            return destroyed;
        }

        INLINE PublisherQos getQos() const SWIFT_COMPUTED_PROPERTY {
            return publisher->get_qos();
        }
        INLINE void setQos(const PublisherQos &qos) SWIFT_COMPUTED_PROPERTY {
            if (publisher->set_qos(qos) != eprosima::fastdds::dds::RETCODE_OK) {
                EPROSIMA_LOG_WARNING(Publisher, "Failed to set QoS");
            }
        }

    private:
        _Publisher * _Nonnull publisher;
        Participant::DomainParticipant * _Nonnull participant;

        bool destroyed = false;

        friend class DataWriter;
    } SWIFT_NONCOPYABLE;

}
