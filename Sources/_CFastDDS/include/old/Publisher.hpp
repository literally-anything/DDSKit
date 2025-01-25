#pragma once

#include <string>

#include "types.hpp"
#include "DomainParticipant.hpp"

#include <fastdds/dds/publisher/Publisher.hpp>
#include <fastdds/dds/publisher/PublisherListener.hpp>
#include <fastdds/dds/publisher/qos/PublisherQos.hpp>
#include <fastdds/dds/core/status/StatusMask.hpp>

namespace fastdds {
    typedef epfastdds::PublisherListener _PublisherListener;

    namespace _Publisher {
        typedef epfastdds::Publisher Publisher;
        typedef epfastdds::PublisherQos PublisherQos;

        bool compareQos(PublisherQos rhs, PublisherQos lhs);
        PublisherQos getDefaultQos(_DomainParticipant::DomainParticipant *participant);

        Publisher *create(_DomainParticipant::DomainParticipant *participant, const std::string &profile);
        Publisher *create(_DomainParticipant::DomainParticipant *participant, const PublisherQos &qos);
        DDSReturnCode destroy(Publisher *publisher);
        DDSReturnCode destroyEntities(Publisher *publisher);

        PublisherQos getQos(Publisher *publisher);
        DDSReturnCode setQos(Publisher *publisher, const PublisherQos qos);
    }
}
