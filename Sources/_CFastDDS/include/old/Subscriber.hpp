#pragma once

#include <string>

#include "types.hpp"
#include "DomainParticipant.hpp"

#include <fastdds/dds/subscriber/Subscriber.hpp>
#include <fastdds/dds/subscriber/SubscriberListener.hpp>
#include <fastdds/dds/subscriber/qos/SubscriberQos.hpp>
#include <fastdds/dds/core/status/StatusMask.hpp>

namespace fastdds {
    typedef epfastdds::SubscriberListener _SubscriberListener;

    namespace _Subscriber {
        typedef epfastdds::Subscriber Subscriber;
        typedef epfastdds::SubscriberQos SubscriberQos;

        bool compareQos(SubscriberQos rhs, SubscriberQos lhs);
        SubscriberQos getDefaultQos(_DomainParticipant::DomainParticipant *participant);

        Subscriber *create(_DomainParticipant::DomainParticipant *participant, const std::string &profile);
        Subscriber *create(_DomainParticipant::DomainParticipant *participant, const SubscriberQos &qos);
        DDSReturnCode destroy(Subscriber *subscriber);
        DDSReturnCode destroyEntities(Subscriber *subscriber);

        SubscriberQos getQos(Subscriber *subscriber);
        DDSReturnCode setQos(Subscriber *subscriber, const SubscriberQos qos);
    }
}
