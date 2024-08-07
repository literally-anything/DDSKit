#include "Topic.hpp"

namespace _Topic {
    void Listener::on_inconsistent_topic(Topic *topic, fastdds::InconsistentTopicStatus status) {
        if (onInconsistentTopic != nullptr) {
            onInconsistentTopic(context, topic, status);
        }
    }

    std::shared_ptr<Listener> createListener() {
        return std::make_shared<Listener>();
    }
    Listener *getListenerPtr(std::shared_ptr<Listener> listener) {
        return listener.get();
    }
    void setListenerContext(std::shared_ptr<Listener> listener, void *context) {
        listener->context = context;
    }
    void setListenerInconsistentTopicCallback(std::shared_ptr<Listener> listener,
                                              void(*onInconsistentTopic)(void *context, Topic *topic, fastdds::InconsistentTopicStatus status)) {
        listener->onInconsistentTopic = onInconsistentTopic;
    }

    TopicQos getDefaultQos(_DomainParticipant::DomainParticipant *participant) {
        return participant->get_default_topic_qos();
    }

    Topic *create(_DomainParticipant::DomainParticipant *participant,
                  const std::string &name, const std::string &type, const std::string &profile,
                  Listener *listener, const _StatusMask &mask) {
        return participant->create_topic_with_profile(name, type, profile, listener, mask);
    }
    Topic *create(_DomainParticipant::DomainParticipant *participant,
                  const std::string &name, const std::string &type, const TopicQos &qos,
                  Listener *listener, const _StatusMask &mask) {
        return participant->create_topic(name, type, qos, listener, mask);
    }
    _ReturnCode destroy(Topic *topic) {
        return topic->get_participant()->delete_topic(topic);
    }
}
