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
#include "swift_helpers.hpp"

#include <fastdds/dds/core/status/StatusMask.hpp>
#include <fastdds/dds/core/detail/DDSReturnCode.hpp>
#include <fastdds/dds/subscriber/Subscriber.hpp>
#include <fastdds/dds/subscriber/qos/SubscriberQos.hpp>

class DataReader;

namespace FastDDS {

    class Subscriber final {
    public:
        using _Subscriber = eprosima::fastdds::dds::Subscriber;
        using SubscriberQos = eprosima::fastdds::dds::SubscriberQos;
        using StatusMask = eprosima::fastdds::dds::StatusMask;

        static INLINE SubscriberQos getDefaultQos(const Participant &participantWrapper) SWIFT_NAME(getDefaultQos(participant:)) {
            return participantWrapper.participant->get_default_subscriber_qos();
        }

        INLINE Subscriber(
            const Participant &participantWrapper, const std::string &profileName, bool &success
        ) SWIFT_NAME(init(participant:profile:success:)) : participant(participantWrapper.participant) {
            subscriber = participant->create_subscriber_with_profile(profileName, nullptr, StatusMask::none());
            success = subscriber != nullptr;
        }

        INLINE Subscriber(
            const Participant &participantWrapper, const SubscriberQos &qos, bool &success
        ) SWIFT_NAME(init(participant:profile:success:)) : participant(participantWrapper.participant) {
            subscriber = participant->create_subscriber(qos, nullptr, StatusMask::none());
            success = subscriber != nullptr;
        }

        INLINE eprosima::fastdds::dds::ReturnCode_t destroy() {
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

        INLINE SubscriberQos getQos() const SWIFT_COMPUTED_PROPERTY {
            return subscriber->get_qos();
        }
        INLINE void setQos(const SubscriberQos &qos) SWIFT_COMPUTED_PROPERTY {
            if (subscriber->set_qos(qos) != eprosima::fastdds::dds::RETCODE_OK) {
                EPROSIMA_LOG_WARNING(Subscriber, "Failed to set QoS");
            }
        }

    private:
        _Subscriber * _Nonnull subscriber;
        Participant::DomainParticipant * _Nonnull participant;

        bool destroyed = false;

        friend class DataReader;
    } SWIFT_NONCOPYABLE;

}
