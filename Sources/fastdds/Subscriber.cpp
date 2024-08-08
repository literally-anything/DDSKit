#include "Subscriber.hpp"

namespace _Subscriber {
    bool compareQos(SubscriberQos rhs, SubscriberQos lhs) {
        return rhs == lhs;
    }
    SubscriberQos getDefaultQos(_DomainParticipant::DomainParticipant *participant) {
        return participant->get_default_subscriber_qos();
    }

    Subscriber *create(_DomainParticipant::DomainParticipant *participant, const std::string &profile) {
        return participant->create_subscriber_with_profile(profile, nullptr, _StatusMask::none());
    }
    Subscriber *create(_DomainParticipant::DomainParticipant *participant, const SubscriberQos &qos) {
        return participant->create_subscriber(qos, nullptr, _StatusMask::none());
    }
    _ReturnCode destroy(Subscriber *subscriber) {
        return const_cast<_DomainParticipant::DomainParticipant *>(subscriber->get_participant())->delete_subscriber(subscriber);
    }
    _ReturnCode destroyEntities(Subscriber *subscriber) {
        return subscriber->delete_contained_entities();
    }

    SubscriberQos getQos(Subscriber *subscriber) {
        return subscriber->get_qos();
    }
    _ReturnCode setQos(Subscriber *subscriber, const SubscriberQos qos) {
        return subscriber->set_qos(qos);
    }
}
