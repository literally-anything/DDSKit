/*
 * topic.hpp
 * include
 * 
 * Created by Hunter Baker on 2/04/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <swift/bridging>

#include "common.h"
#include "participant.hpp"
#include "cdr/type_support.hpp"

#include <fastdds/dds/topic/Topic.hpp>

#define MAX_TOPIC_SEARCH_SECONDS 2

class DataWriter;
class DataReader;

namespace FastDDS {

    class Topic final {
    public:
        using _Topic = eprosima::fastdds::dds::Topic;
        using TopicQos = eprosima::fastdds::dds::TopicQos;
        using StatusMask = eprosima::fastdds::dds::StatusMask;
        using TypeSupport = eprosima::fastdds::dds::TypeSupport;


        // class Qos final {
        // public:
        //     INLINE Qos(const Participant &participantWrapper) SWIFT_NAME(init(participant:)) {
        //         qos = participantWrapper.participant->get_default_topic_qos();
        //     }

        //     INLINE const TopicQos &get() const {
        //         return qos;
        //     }

        // private:
        //     TopicQos qos;
        // };


        INLINE Topic(
            const Participant &participantWrapper, const std::string &topicName, const TypeSupportWrapper &typeSupport,
            // const Qos &qos,
            bool &success
        ) SWIFT_NAME(init(participant:topic:typeSupport:success:)) : participant(participantWrapper.participant) {
            topic = participant->find_topic(topicName, eprosima::fastdds::dds::Duration_t(MAX_TOPIC_SEARCH_SECONDS));
            if (topic == nullptr) {
                topic = participant->create_topic(
                    topicName, typeSupport.typeSupport.get_type_name(),
                    participant->get_default_topic_qos(),
                    nullptr, StatusMask::none()
                );
            }
            success = topic != nullptr;
            destroyed = !success;
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t enable() {
            return topic->enable();
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t destroy() {
            if (!destroyed) {
                topic->close();

                auto ret = participant->delete_topic(topic);
                if (ret != eprosima::fastdds::dds::RETCODE_OK) { return ret; }

                destroyed = true;
            }
            return eprosima::fastdds::dds::RETCODE_OK;
        }
        INLINE bool getDestroyed() const SWIFT_COMPUTED_PROPERTY {
            return destroyed;
        }

        INLINE std::string getName() const SWIFT_COMPUTED_PROPERTY {
            return topic->get_name();
        }

        INLINE std::string getTypeName() const SWIFT_COMPUTED_PROPERTY {
            return topic->get_type_name();
        }

    private:
        _Topic * _Nonnull topic;
        Participant::DomainParticipant * _Nonnull participant;

        bool destroyed = false;

        friend class DataWriter;
        friend class DataReader;
    } SWIFT_NONCOPYABLE;

}
