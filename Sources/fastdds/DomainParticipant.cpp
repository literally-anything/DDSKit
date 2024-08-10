#include "DomainParticipant.hpp"

namespace _DomainParticipant {
    bool compareQos(DomainParticipantQos rhs, DomainParticipantQos lhs) {
        return rhs == lhs;
    }

    Listener::Listener(DDSKitInternal::ParticipantCallbacks *callbacks) : callbacks(callbacks) {}
    void Listener::on_participant_discovery(DomainParticipant *participant,
                                            fastrtps::ParticipantDiscoveryStatus reason,
                                            const fastdds::ParticipantBuiltinTopicData &info,
                                            bool &should_be_ignored) {
        callbacks->participantDiscovered(participant, &reason, &info);
    }

    Listener *createListener(DDSKitInternal::ParticipantCallbacks *callbacks) {
        return new Listener(callbacks);
    }
    void destroyListener(Listener *listener) {
        listener->~Listener();
    }

    inline DomainParticipantFactory *getFactory() {
        return DomainParticipantFactory::get_instance();
    }

    _ReturnCode loadProfiles() {
        return getFactory()->load_profiles();
    }
    DomainParticipantQos getDefaultQos() {
        return getFactory()->get_default_participant_qos();
    }

    DomainParticipant *create(fastdds::DomainId_t domain, const std::string &profile) {
        return getFactory()->create_participant_with_profile(domain, profile, nullptr, _StatusMask::none());
    }
    DomainParticipant *create(fastdds::DomainId_t domain, const DomainParticipantQos &qos) {
        return getFactory()->create_participant(domain, qos, nullptr, _StatusMask::none());
    }
    _ReturnCode destroy(DomainParticipant *participant) {
        return getFactory()->delete_participant(participant);
    }
    _ReturnCode destroyEntities(DomainParticipant *participant) {
        return participant->delete_contained_entities();
    }

    DomainParticipantQos getQos(DomainParticipant *participant) {
        return participant->get_qos();
    }
    _ReturnCode setQos(DomainParticipant *participant, const DomainParticipantQos qos) {
        return participant->set_qos(qos);
    }
    _ReturnCode setListener(DomainParticipant *participant, Listener *listener, const _StatusMask &mask) {
        return participant->set_listener(listener, mask);
    }
    _DomainId getDomainId(DomainParticipant *participant) {
        return participant->get_domain_id();
    }

    _ReturnCode registerType(DomainParticipant *participant,
                             _TypeSupport type, const std::string &name) {
        return participant->register_type(type, name);
    }
}
