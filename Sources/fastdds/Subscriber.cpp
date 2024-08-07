#include "Subscriber.hpp"

namespace _Subscriber {
    bool compareQos(SubscriberQos rhs, SubscriberQos lhs) {
        return rhs == lhs;
    }
    SubscriberQos getDefaultQos(_DomainParticipant::DomainParticipant *participant) {
        return participant->get_default_subscriber_qos();
    }

    Subscriber *create(_DomainParticipant::DomainParticipant *participant, const std::string &profile,
                       _SubscriberListener *listener, const _StatusMask &mask) {
        return participant->create_subscriber_with_profile(profile, listener, mask);
    }
    Subscriber *create(_DomainParticipant::DomainParticipant *participant, const SubscriberQos &qos,
                       _SubscriberListener *listener, const _StatusMask &mask) {
        return participant->create_subscriber(qos, listener, mask);
    }
    _ReturnCode destroy(Subscriber *subscriber) {
        return const_cast<_DomainParticipant::DomainParticipant *>(subscriber->get_participant())->delete_subscriber(subscriber);
    }
    _ReturnCode destroyEntities(Subscriber *subscriber) {
        return subscriber->delete_contained_entities();
    }
}
