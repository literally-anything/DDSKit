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

#include <fastdds/dds/core/status/StatusMask.hpp>
#include <fastdds/dds/topic/Topic.hpp>
#include <fastdds/dds/topic/TopicListener.hpp>
#include <fastdds/dds/topic/qos/TopicQos.hpp>

class DataWriter;
class DataReader;

namespace FastDDS {

    class Topic final {
    public:
        using _Topic = eprosima::fastdds::dds::Topic;
        using TopicQos = eprosima::fastdds::dds::TopicQos;
        using StatusMask = eprosima::fastdds::dds::StatusMask;
        using TypeSupport = eprosima::fastdds::dds::TypeSupport;

        using onInconsistentTopic_t = void (^ SENDABLE _Nonnull)();
        struct Callbacks {
            onInconsistentTopic_t inconsitentTopicCallback;
        };

        static INLINE TopicQos getDefaultQos(const Participant &participantWrapper) SWIFT_NAME(getDefaultQos(participant:)) {
            return participantWrapper.participant->get_default_topic_qos();
        }

        INLINE Topic(
            const Participant &participantWrapper, const std::string &topicName, TypeSupport typeSupport,
            const std::string &profileName,
            bool &success
        ) SWIFT_NAME(init(participant:topic:typeSupport:profile:success:)) : participant(participantWrapper.participant) {
            topic = participant->create_topic_with_profile(
                topicName, typeSupport.get_type_name(),
                profileName,
                nullptr, StatusMask::none()
            );
            success = topic != nullptr;
            destroyed = !success;
        }

        INLINE Topic(
            const Participant &participantWrapper, const std::string &topicName, TypeSupport typeSupport,
            const TopicQos &qos,
            bool &success
        ) SWIFT_NAME(init(participant:topic:typeSupport:profile:success:)) : participant(participantWrapper.participant) {
            topic = participant->create_topic(
                topicName, typeSupport.get_type_name(),
                qos,
                nullptr, StatusMask::none()
            );
            success = topic != nullptr;
            destroyed = !success;
        }

        INLINE void enable() {
            topic->enable();
        }

        INLINE eprosima::fastdds::dds::ReturnCode_t destroy() {
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

        INLINE TopicQos getQos() const SWIFT_COMPUTED_PROPERTY {
            return topic->get_qos();
        }
        INLINE void setQos(const TopicQos &qos) SWIFT_COMPUTED_PROPERTY {
            if (topic->set_qos(qos) != eprosima::fastdds::dds::RETCODE_OK) {
                EPROSIMA_LOG_WARNING(Topic, "Failed to set QoS");
            }
        }

        INLINE void setCallbacks(const Callbacks &callbacks) {
            listener = std::make_unique<Listener>(callbacks);
            topic->set_listener(listener.get(), StatusMask::inconsistent_topic());
        }

    private:
        class Listener final : public eprosima::fastdds::dds::TopicListener {
        public:
            explicit Listener(const Callbacks &callbacks);
            ~Listener() override;

            // Non-copyable because it would deallocate the blocks
            Listener( const Listener& ) = delete;
            Listener& operator=( const Listener& ) = delete;

            void on_inconsistent_topic(_Topic * _Nullable topic, eprosima::fastdds::dds::InconsistentTopicStatus status) override;
        
        private:
            onInconsistentTopic_t inconsitentTopicCallback;
        };

        _Topic * _Nonnull topic;
        Participant::DomainParticipant * _Nonnull participant;
        std::unique_ptr<Listener> listener;

        bool destroyed = false;

        friend class DataWriter;
        friend class DataReader;
    } SWIFT_NONCOPYABLE;

}
