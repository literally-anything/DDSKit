#include "Publisher.hpp"

namespace _Publisher {
    bool compareQos(PublisherQos rhs, PublisherQos lhs) {
        return rhs == lhs;
    }
    PublisherQos getDefaultQos(_DomainParticipant::DomainParticipant *participant) {
        return participant->get_default_publisher_qos();
    }

    Publisher *create(_DomainParticipant::DomainParticipant *participant, const std::string &profile) {
        return participant->create_publisher_with_profile(profile, nullptr, _StatusMask::none());
    }
    Publisher *create(_DomainParticipant::DomainParticipant *participant, const PublisherQos &qos) {
        return participant->create_publisher(qos, nullptr, _StatusMask::none());
    }
    _ReturnCode destroy(Publisher *publisher) {
        return const_cast<_DomainParticipant::DomainParticipant *>(publisher->get_participant())->delete_publisher(publisher);
    }
    _ReturnCode destroyEntities(Publisher *publisher) {
        return publisher->delete_contained_entities();
    }

    PublisherQos getQos(Publisher *publisher) {
        return publisher->get_qos();
    }
    _ReturnCode setQos(Publisher *publisher, const PublisherQos qos) {
        return publisher->set_qos(qos);
    }
}
