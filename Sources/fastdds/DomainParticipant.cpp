#include "DomainParticipant.hpp"

namespace fastdds {
    namespace _DomainParticipant {
        bool compareQos(DomainParticipantQos rhs, DomainParticipantQos lhs) {
            return rhs == lhs;
        }

        Listener::Listener(DDSKitInternal::ParticipantCallbacks *callbacks) : callbacks(callbacks) {}
        void Listener::on_participant_discovery(DomainParticipant *participant,
                                                epfastrtps::ParticipantDiscoveryStatus reason,
                                                const DDSParticipantBuiltinTopicData &info,
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

        DDSReturnCode loadProfiles() {
            return getFactory()->load_profiles();
        }
        DomainParticipantQos getDefaultQos() {
            return getFactory()->get_default_participant_qos();
        }

        DomainParticipant *create(DDSDomainId domain, const std::string &profile) {
            return getFactory()->create_participant_with_profile(domain, profile, nullptr, _StatusMask::none());
        }
        DomainParticipant *create(DDSDomainId domain, const DomainParticipantQos &qos) {
            return getFactory()->create_participant(domain, qos, nullptr, _StatusMask::none());
        }
        DDSReturnCode destroy(DomainParticipant *participant) {
            return getFactory()->delete_participant(participant);
        }
        DDSReturnCode destroyEntities(DomainParticipant *participant) {
            return participant->delete_contained_entities();
        }

        DomainParticipantQos getQos(DomainParticipant *participant) {
            return participant->get_qos();
        }
        DDSReturnCode setQos(DomainParticipant *participant, const DomainParticipantQos qos) {
            return participant->set_qos(qos);
        }
        DDSReturnCode setListener(DomainParticipant *participant, Listener *listener, const _StatusMask &mask) {
            return participant->set_listener(listener, mask);
        }
        DDSDomainId getDomainId(DomainParticipant *participant) {
            return participant->get_domain_id();
        }

        DDSReturnCode registerType(DomainParticipant *participant,
                                   _TypeSupport type, const std::string &name) {
            return participant->register_type(type, name);
        }
    }
}
