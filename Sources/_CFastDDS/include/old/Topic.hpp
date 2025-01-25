/*
 * Topic.hpp
 * old
 * 
 * Created by Hunter Baker on 8/04/2024
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <string>

#include "types.hpp"
#include "DomainParticipant.hpp"
#include "../../../.compatibility-headers/_FastDDSHelpers-Swift.h"

#include <fastdds/dds/topic/Topic.hpp>
#include <fastdds/dds/topic/TopicListener.hpp>
#include <fastdds/dds/topic/qos/TopicQos.hpp>
#include <fastdds/dds/core/status/StatusMask.hpp>

namespace fastdds {
    typedef epfastdds::InconsistentTopicStatus DDSInconsistentTopicStatus;

    typedef epfastdds::TopicListener _TopicListener;

    namespace _Topic {
        typedef epfastdds::Topic Topic;
        typedef epfastdds::TopicQos TopicQos;
        typedef epfastdds::TopicDataType TopicDataType;

        bool compareQos(TopicQos rhs, TopicQos lhs);

        class Listener : public _TopicListener {
        private:
            _FastDDSHelpers::TopicCallbacks *callbacks;

        public:
            Listener(_FastDDSHelpers::TopicCallbacks *callbacks);

            void on_inconsistent_topic(Topic *topic, DDSInconsistentTopicStatus status) override;
        };

        Listener *createListener(_FastDDSHelpers::TopicCallbacks *callbacks);
        void destroyListener(Listener *listener);

        TopicQos getDefaultQos(_DomainParticipant::DomainParticipant *participant);

        Topic *create(_DomainParticipant::DomainParticipant *participant,
                    const std::string &name, const std::string &type, const std::string &profile);
        Topic *create(_DomainParticipant::DomainParticipant *participant,
                    const std::string &name, const std::string &type, const TopicQos &qos);
        DDSReturnCode destroy(Topic *topic);

        TopicQos getQos(Topic *topic);
        DDSReturnCode setQos(Topic *topic, const TopicQos qos);
        DDSReturnCode setListener(Topic *topic, Listener *listener, const _StatusMask &mask);
    }
}
