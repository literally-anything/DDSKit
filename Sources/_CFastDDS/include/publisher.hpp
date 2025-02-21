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

#include <fastdds/dds/publisher/Publisher.hpp>
#include <fastdds/dds/publisher/qos/PublisherQos.hpp>

class DataWriter;

namespace FastDDS {

    class Publisher final {
    public:
        using _Publisher = eprosima::fastdds::dds::Publisher;
        using PublisherQos = eprosima::fastdds::dds::PublisherQos;
        using StatusMask = eprosima::fastdds::dds::StatusMask;


        // class Qos final {
        // public:
        //     INLINE Qos(const Participant &participantWrapper) SWIFT_NAME(init(participant:)) {
        //         qos = participantWrapper.participant->get_default_publisher_qos();
        //     }

        //     INLINE const PublisherQos &get() const {
        //         return qos;
        //     }

        // private:
        //     PublisherQos qos;
        // };


        INLINE Publisher(
            const Participant &participantWrapper,
            // const Qos &qos,
            bool &success
        ) SWIFT_NAME(init(participant:success:)) : participant(participantWrapper.participant) {
            publisher = participant->create_publisher(participant->get_default_publisher_qos(), nullptr, StatusMask::none());
            success = publisher != nullptr;
            destroyed = !success;
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t enable() {
            return publisher->enable();
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t destroy() {
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

    private:
        _Publisher * _Nonnull publisher;
        Participant::DomainParticipant * _Nonnull participant;

        bool destroyed = false;

        friend class DataWriter;
    } SWIFT_NONCOPYABLE;

}
