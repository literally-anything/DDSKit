#pragma once

#include "types.hpp"
#include <string>
#include "DomainParticipant.hpp"
#include <fastdds/dds/topic/Topic.hpp>
#include <fastdds/dds/topic/TopicListener.hpp>
#include <fastdds/dds/topic/qos/TopicQos.hpp>
#include <fastdds/dds/core/status/StatusMask.hpp>
typedef fastdds::TopicListener _TopicListener;

namespace _Topic {
    typedef fastdds::Topic Topic;
    typedef fastdds::TopicQos TopicQos;
    typedef eprosima::fastdds::dds::TopicDataType TopicDataType;

    bool compareQos(TopicQos rhs, TopicQos lhs);

    class Listener : public _TopicListener {
    public:
        void *context = nullptr;

        void(*onInconsistentTopic)(void *context, Topic *topic, fastdds::InconsistentTopicStatus status) = nullptr;

        void on_inconsistent_topic(Topic *topic, fastdds::InconsistentTopicStatus status) override;
    };

    Listener *createListener(void(*onInconsistentTopic)(void *context, Topic *topic, fastdds::InconsistentTopicStatus status));
    void destroyListener(Listener *listener);
    void setListenerContext(Listener *listener, void *context);

    TopicQos getDefaultQos(_DomainParticipant::DomainParticipant *participant);

    Topic *create(_DomainParticipant::DomainParticipant *participant,
                  const std::string &name, const std::string &type, const std::string &profile);
    Topic *create(_DomainParticipant::DomainParticipant *participant,
                  const std::string &name, const std::string &type, const TopicQos &qos);
    _ReturnCode destroy(Topic *topic);

    TopicQos getQos(Topic *topic);
    _ReturnCode setQos(Topic *topic, const TopicQos qos);
    _ReturnCode setListener(Topic *topic, Listener *listener, const _StatusMask &mask);
}

void test(std::function<void(int)> func);
