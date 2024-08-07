#pragma once

#include "types.hpp"
#include <string>
#include "DomainParticipant.hpp"
#include <fastdds/dds/subscriber/Subscriber.hpp>
#include <fastdds/dds/subscriber/SubscriberListener.hpp>
#include <fastdds/dds/subscriber/qos/SubscriberQos.hpp>
#include <fastdds/dds/core/status/StatusMask.hpp>

typedef fastdds::SubscriberListener _SubscriberListener;

namespace _Subscriber {
    typedef fastdds::Subscriber Subscriber;
    typedef fastdds::SubscriberQos SubscriberQos;

    bool compareQos(SubscriberQos rhs, SubscriberQos lhs);
    SubscriberQos getDefaultQos(_DomainParticipant::DomainParticipant *participant);

    Subscriber *create(_DomainParticipant::DomainParticipant *participant, const std::string &profile,
                       _SubscriberListener *listener = nullptr, const _StatusMask &mask = _StatusMask::all());
    Subscriber *create(_DomainParticipant::DomainParticipant *participant, const SubscriberQos &qos,
                       _SubscriberListener *listener = nullptr, const _StatusMask &mask = _StatusMask::all());
    _ReturnCode destroy(Subscriber *subscriber);
    _ReturnCode destroyEntities(Subscriber *subscriber);
}
