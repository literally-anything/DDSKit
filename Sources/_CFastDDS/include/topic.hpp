/*
 * topic.hpp
 * include
 * 
 * Created by Hunter Baker on 2/04/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#if __has_include(<swift/bridging>)
# include <swift/bridging>
#else
# include "utils/swift_bridging.h"
#endif

#include "common.h"
#include "participant.hpp"
#include "types/type_support.hpp"

#include <fastdds/dds/topic/Topic.hpp>

class DataWriter;
class DataReader;

namespace FastDDS {

    class Topic final {
    public:
        using _Topic = eprosima::fastdds::dds::Topic;
        using TopicQos = eprosima::fastdds::dds::TopicQos;
        using StatusMask = eprosima::fastdds::dds::StatusMask;
        using TypeSupport = eprosima::fastdds::dds::TypeSupport;

        using _ContentFilteredTopic = eprosima::fastdds::dds::ContentFilteredTopic;


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
            const Participant &participantWrapper, const std::string &topicName, const Types::TypeSupport &typeSupport,
            // const Qos &qos,
            eprosima::fastdds::dds::ReturnCode_t &ret
        ) SWIFT_NAME(init(participant:topic:typeSupport:ret:)) : participant(participantWrapper.participant) {

            // Stops two threads from creating the same topic at the same time
            // This is a problem because one will fail after it has already verified the topic does not exist
            static std::mutex mutex;
            std::lock_guard<std::mutex> lock(mutex);
            
            topic = participant->find_topic(topicName, eprosima::fastdds::dds::Duration_t(0));

            // If the topic exists but the type is different, then it is not the same topic, so we destroy out proxy
            if (topic != nullptr && typeSupport.getName() != topic->get_type_name()) {
                ret = eprosima::fastdds::dds::RETCODE_PRECONDITION_NOT_MET;
                return;
            }

            // If the topic does not exist, create it
            if (topic == nullptr) {
                topic = participant->create_topic(
                    topicName, typeSupport.typeSupport.get_type_name(),
                    participant->get_default_topic_qos(),
                    nullptr, StatusMask::none()
                );
            }

            bool success = topic != nullptr;
            ret = success ? eprosima::fastdds::dds::RETCODE_OK : eprosima::fastdds::dds::RETCODE_ERROR;
            destroyed = !success;
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t enable() {
            return topic->enable();
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t destroy() {
            if (!destroyed) {
                if (contentFilteredTopic != nullptr) {
                    participant->delete_contentfilteredtopic(contentFilteredTopic);
                }

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

        INLINE void * _Nonnull getNative() const SWIFT_COMPUTED_PROPERTY {
            return topic;
        }

        NODISCARD INLINE bool setContentFiler(
            const std::string &name, const std::string &expression, const std::vector<std::string> &params, const std::string &filter
        ) SWIFT_NAME(setContentFilter(name:expression:params:filter:)) {
            // Stops two threads from creating the same content filtered topic at the same time
            static std::mutex mutex;
            std::lock_guard<std::mutex> lock(mutex);

            // If the content filtered topic is already set, delete it
            if (contentFilteredTopic != nullptr) {
                participant->delete_contentfilteredtopic(contentFilteredTopic);
            }

            // Lookup the content filtered topic, but if it does not exist, create it
            contentFilteredTopic = dynamic_cast<_ContentFilteredTopic *>(participant->lookup_topicdescription(name));
            if (contentFilteredTopic == nullptr) {
                contentFilteredTopic = participant->create_contentfilteredtopic(
                    name, topic, expression, params, filter.c_str()
                );
            }

            return contentFilteredTopic != nullptr;
        }

    private:
        _Topic * _Nonnull topic;
        Participant::DomainParticipant * _Nonnull participant;

        _ContentFilteredTopic * _Nullable contentFilteredTopic = nullptr;

        bool destroyed = false;

        friend class DataWriter;
        friend class DataReader;
    } SWIFT_NONCOPYABLE SENDABLE;

}
