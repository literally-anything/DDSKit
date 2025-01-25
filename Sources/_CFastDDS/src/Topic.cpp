/*
 * Topic.cpp
 * src
 * 
 * Created by Hunter Baker on 8/19/2024
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#include "old/Topic.hpp"

namespace fastdds {
    namespace _Topic {
        bool compareQos(TopicQos rhs, TopicQos lhs) {
            return rhs == lhs;
        }

        Listener::Listener(_FastDDSHelpers::TopicCallbacks *callbacks) : callbacks(callbacks) {}
        void Listener::on_inconsistent_topic(Topic *topic, DDSInconsistentTopicStatus status) {
            callbacks->inconsistentTopic(&status);
        }

        Listener *createListener(_FastDDSHelpers::TopicCallbacks *callbacks) {
            return new Listener(callbacks);
        }
        void destroyListener(Listener *listener) {
            listener->~Listener();
        }

        TopicQos getDefaultQos(_DomainParticipant::DomainParticipant *participant) {
            return participant->get_default_topic_qos();
        }

        Topic *create(_DomainParticipant::DomainParticipant *participant,
                    const std::string &name, const std::string &type, const std::string &profile) {
            return participant->create_topic_with_profile(name, type, profile, nullptr, _StatusMask::none());
        }
        Topic *create(_DomainParticipant::DomainParticipant *participant,
                    const std::string &name, const std::string &type, const TopicQos &qos) {
            return participant->create_topic(name, type, qos, nullptr, _StatusMask::none());
        }
        DDSReturnCode destroy(Topic *topic) {
            return topic->get_participant()->delete_topic(topic);
        }

        TopicQos getQos(Topic *topic) {
            return topic->get_qos();
        }
        DDSReturnCode setQos(Topic *topic, const TopicQos qos) {
            return topic->set_qos(qos);
        }
        DDSReturnCode setListener(Topic *topic, Listener *listener, const _StatusMask &mask) {
            return topic->set_listener(listener, mask);
        }
    }
}
