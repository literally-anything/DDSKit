#include "DomainParticipant.hpp"

namespace _DomainParticipant {
    bool compareQos(DomainParticipantQos rhs, DomainParticipantQos lhs) {
        return rhs == lhs;
    }

    void Listener::on_participant_discovery(DomainParticipant *participant,
                                            fastrtps::ParticipantDiscoveryStatus reason,
                                            const fastdds::ParticipantBuiltinTopicData &info,
                                            bool &should_be_ignored) {
        if (onParticipantDiscovery != nullptr) {
            should_be_ignored = onParticipantDiscovery(context, participant, reason, std::move(const_cast<fastdds::ParticipantBuiltinTopicData &>(info)));
        }
    }
    void Listener::on_data_reader_discovery(DomainParticipant *participant,
                                            fastrtps::ReaderDiscoveryStatus reason,
                                            const fastdds::SubscriptionBuiltinTopicData &info,
                                            bool &should_be_ignored) {
        if (onDataReaderDiscovery != nullptr) {
            should_be_ignored = onDataReaderDiscovery(context, participant, reason, std::move(const_cast<fastdds::SubscriptionBuiltinTopicData &>(info)));
        }
    }
    void Listener::on_data_writer_discovery(DomainParticipant *participant,
                                            fastrtps::WriterDiscoveryStatus reason,
                                            const fastdds::PublicationBuiltinTopicData &info,
                                            bool &should_be_ignored) {
        if (onDataWriterDiscovery != nullptr) {
            should_be_ignored = onDataWriterDiscovery(context, participant, reason, std::move(const_cast<fastdds::PublicationBuiltinTopicData &>(info)));
        }
    }

    Listener *createListener() {
        return new Listener();
    }
    void destroyListener(Listener *listener) {
        listener->~Listener();
    }
    void setListenerContext(Listener *listener, void *context) {
        listener->context = context;
    }
    void setListenerParticipantDiscoveryCallback(Listener *listener,
                                                 bool(*onParticipantDiscovery)(void *context, DomainParticipant *participant, fastrtps::ParticipantDiscoveryStatus reason, fastdds::ParticipantBuiltinTopicData &&info)) {
        listener->onParticipantDiscovery = onParticipantDiscovery;
    }
    void setListenerDataReaderDiscoveryCallback(Listener *listener,
                                                bool(*onDataReaderDiscovery)(void *context, DomainParticipant *participant, fastrtps::ReaderDiscoveryStatus reason, fastdds::SubscriptionBuiltinTopicData &&info)) {
        listener->onDataReaderDiscovery = onDataReaderDiscovery;
    }
    void setListenerDataWriterDiscoveryCallback(Listener *listener,
                                                bool(*onDataWriterDiscovery)(void *context, DomainParticipant *participant, fastrtps::WriterDiscoveryStatus reason, fastdds::PublicationBuiltinTopicData &&info)) {
        listener->onDataWriterDiscovery = onDataWriterDiscovery;
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

    _ReturnCode registerType(DomainParticipant *participant,
                             _TypeSupport type, const std::string &name) {
        return participant->register_type(type, name);
    }
}
