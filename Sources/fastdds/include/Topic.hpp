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

    class Listener : public _TopicListener {
    public:
        void *context = nullptr;

        void(*onInconsistentTopic)(void *context, Topic *topic, fastdds::InconsistentTopicStatus status) = nullptr;

        void on_inconsistent_topic(Topic *topic, fastdds::InconsistentTopicStatus status) override;
    };

    std::shared_ptr<Listener> createListener();
    Listener *getListenerPtr(std::shared_ptr<Listener> listener);
    void setListenerContext(std::shared_ptr<Listener> listener, void *context);
    void setListenerInconsistentTopicCallback(std::shared_ptr<Listener> listener,
                                              void(*onInconsistentTopic)(void *context, Topic *topic, fastdds::InconsistentTopicStatus status));

    TopicQos getDefaultQos(_DomainParticipant::DomainParticipant *participant);

    Topic *create(_DomainParticipant::DomainParticipant *participant,
                  const std::string &name, const std::string &type, const std::string &profile,
                  Listener *listener = nullptr, const _StatusMask &mask = _StatusMask::all());
    Topic *create(_DomainParticipant::DomainParticipant *participant,
                  const std::string &name, const std::string &type, const TopicQos &qos,
                  Listener *listener = nullptr, const _StatusMask &mask = _StatusMask::all());
    _ReturnCode destroy(Topic *topic);
}
