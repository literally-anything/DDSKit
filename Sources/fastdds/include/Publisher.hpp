#pragma once

#include "types.hpp"
#include <string>
#include "DomainParticipant.hpp"
#include <fastdds/dds/publisher/Publisher.hpp>
#include <fastdds/dds/publisher/PublisherListener.hpp>
#include <fastdds/dds/publisher/qos/PublisherQos.hpp>
#include <fastdds/dds/core/status/StatusMask.hpp>

typedef fastdds::PublisherListener _PublisherListener;

namespace _Publisher {
    typedef fastdds::Publisher Publisher;
    typedef fastdds::PublisherQos PublisherQos;

    bool compareQos(PublisherQos rhs, PublisherQos lhs);
    PublisherQos getDefaultQos(_DomainParticipant::DomainParticipant *participant);

    Publisher *create(_DomainParticipant::DomainParticipant *participant, const std::string &profile,
                      _PublisherListener *listener = nullptr, const _StatusMask &mask = _StatusMask::all());
    Publisher *create(_DomainParticipant::DomainParticipant *participant, const PublisherQos &qos,
                      _PublisherListener *listener = nullptr, const _StatusMask &mask = _StatusMask::all());
    _ReturnCode destroy(Publisher *publisher);
    _ReturnCode destroyEntities(Publisher *publisher);

    PublisherQos getQos(Publisher *publisher);
    _ReturnCode setQos(Publisher *publisher, const PublisherQos qos);
}
