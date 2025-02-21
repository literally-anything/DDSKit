/*
 * subscriber.hpp
 * src
 * 
 * Created by Hunter Baker on 2/04/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <swift/bridging>

#include "common.h"
#include "participant.hpp"

#include <fastdds/dds/subscriber/Subscriber.hpp>
#include <fastdds/dds/subscriber/qos/SubscriberQos.hpp>

class DataReader;

namespace FastDDS {

    class Subscriber final {
    public:
        using _Subscriber = eprosima::fastdds::dds::Subscriber;
        using SubscriberQos = eprosima::fastdds::dds::SubscriberQos;
        using StatusMask = eprosima::fastdds::dds::StatusMask;


        // class Qos final {
        // public:
        //     INLINE Qos(const Participant &participantWrapper) SWIFT_NAME(init(participant:)) {
        //         qos = participantWrapper.participant->get_default_subscriber_qos();
        //     }

        //     INLINE const SubscriberQos &get() const {
        //         return qos;
        //     }

        // private:
        //     SubscriberQos qos;
        // };


        INLINE Subscriber(
            const Participant &participantWrapper,
            // const Qos &qos,
            bool &success
        ) SWIFT_NAME(init(participant:success:)) : participant(participantWrapper.participant) {
            subscriber = participant->create_subscriber(participant->get_default_subscriber_qos(), nullptr, StatusMask::none());
            success = subscriber != nullptr;
            destroyed = !success;
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t enable() {
            return subscriber->enable();
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t destroy() {
            if (!destroyed) {
                auto ret = subscriber->delete_contained_entities();
                if (ret != eprosima::fastdds::dds::RETCODE_OK) { return ret; }

                ret = participant->delete_subscriber(subscriber);
                if (ret != eprosima::fastdds::dds::RETCODE_OK) { return ret; }

                destroyed = true;
            }
            return eprosima::fastdds::dds::RETCODE_OK;
        }
        INLINE bool getDestroyed() const SWIFT_COMPUTED_PROPERTY {
            return destroyed;
        }

    private:
        _Subscriber * _Nonnull subscriber;
        Participant::DomainParticipant * _Nonnull participant;

        bool destroyed = false;

        friend class DataReader;
    } SWIFT_NONCOPYABLE;

}
