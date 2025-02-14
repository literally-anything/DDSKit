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
#include "swift_helpers.hpp"

#include <fastdds/dds/core/status/StatusMask.hpp>
#include <fastdds/dds/topic/Topic.hpp>
#include <fastdds/dds/topic/TopicListener.hpp>
#include <fastdds/dds/topic/qos/TopicQos.hpp>

class DataWriter;
class DataReader;

class Topic final {
public:
    using _Topic = eprosima::fastdds::dds::Topic;
    using TopicQos = eprosima::fastdds::dds::TopicQos;
    using StatusMask = eprosima::fastdds::dds::StatusMask;
    using TypeSupport = eprosima::fastdds::dds::TypeSupport;

    static INLINE TopicQos getDefaultQos(const Participant &participantWrapper) SWIFT_NAME(getDefaultQos(participant:)) {
        return participantWrapper.participant->get_default_topic_qos();
    }

    INLINE Topic(
        const Participant &participantWrapper, const std::string &topicName, TypeSupport typeSupport,
        const std::string &profileName,
        _FastDDSHelpers::TopicCallbacks * _Nonnull callbacks, const StatusMask &statusMask,
        bool &success
    ) SWIFT_NAME(init(participant:topic:typeSupport:profile:callbacks:statusMask:success:)) : participant(participantWrapper.participant), listener(std::make_unique<Listener>(callbacks)) {
        topic = participant->create_topic_with_profile(
            topicName, typeSupport.get_type_name(),
            profileName,
            listener.get(), statusMask
        );
        success = topic != nullptr;
    }

    INLINE Topic(
        const Participant &participantWrapper, const std::string &topicName, TypeSupport typeSupport,
        const TopicQos &qos,
        _FastDDSHelpers::TopicCallbacks * _Nonnull callbacks, const StatusMask &statusMask,
        bool &success
    ) SWIFT_NAME(init(participant:topic:typeSupport:profile:callbacks:statusMask:success:)) : participant(participantWrapper.participant), listener(std::make_unique<Listener>(callbacks)) {
        topic = participant->create_topic(
            topicName, typeSupport.get_type_name(),
            qos,
            listener.get(), statusMask
        );
        success = topic != nullptr;
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

    INLINE StatusMask getStatusMask() const SWIFT_COMPUTED_PROPERTY {
        return topic->get_status_mask();
    }
    INLINE void setStatusMask(const StatusMask &mask) SWIFT_COMPUTED_PROPERTY {
        topic->set_listener(listener.get(), mask);
    }

    INLINE TopicQos getQos() const SWIFT_COMPUTED_PROPERTY {
        return topic->get_qos();
    }
    INLINE void setQos(const TopicQos &qos) SWIFT_COMPUTED_PROPERTY {
        if (topic->set_qos(qos) != eprosima::fastdds::dds::RETCODE_OK) {
            EPROSIMA_LOG_WARNING(Topic, "Failed to set QoS");
        }
    }

private:
    class Listener final : public eprosima::fastdds::dds::TopicListener {
    public:
        _FastDDSHelpers::TopicCallbacks * _Nonnull callbacks;

        INLINE explicit Listener(_FastDDSHelpers::TopicCallbacks * _Nonnull callbacks) : callbacks(callbacks) {}
    };

    _Topic * _Nonnull topic;
    Participant::DomainParticipant * _Nonnull participant;
    std::unique_ptr<Listener> listener;

    bool destroyed = false;

    friend class DataWriter;
    friend class DataReader;
} SWIFT_NONCOPYABLE;
