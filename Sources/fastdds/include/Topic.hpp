#pragma once

#include <string>

#include "types.hpp"
#include "DomainParticipant.hpp"
#include "../../../.compatibility-headers/DDSKitInternal-Swift.h"

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
            DDSKitInternal::TopicCallbacks *callbacks;

        public:
            Listener(DDSKitInternal::TopicCallbacks *callbacks);

            void on_inconsistent_topic(Topic *topic, DDSInconsistentTopicStatus status) override;
        };

        Listener *createListener(DDSKitInternal::TopicCallbacks *callbacks);
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
