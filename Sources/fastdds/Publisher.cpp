#include "Publisher.hpp"

namespace _Publisher {
    bool compareQos(PublisherQos rhs, PublisherQos lhs) {
        return rhs == lhs;
    }
    PublisherQos getDefaultQos(_DomainParticipant::DomainParticipant *participant) {
        return participant->get_default_publisher_qos();
    }

    Publisher *create(_DomainParticipant::DomainParticipant *participant, const std::string &profile,
                      _PublisherListener *listener, const _StatusMask &mask) {
        return participant->create_publisher_with_profile(profile, listener, mask);
    }
    Publisher *create(_DomainParticipant::DomainParticipant *participant, const PublisherQos &qos,
                      _PublisherListener *listener, const _StatusMask &mask) {
        return participant->create_publisher(qos, listener, mask);
    }
    _ReturnCode destroy(Publisher *publisher) {
        return const_cast<_DomainParticipant::DomainParticipant *>(publisher->get_participant())->delete_publisher(publisher);
    }
    _ReturnCode destroyEntities(Publisher *publisher) {
        return publisher->delete_contained_entities();
    }
}
