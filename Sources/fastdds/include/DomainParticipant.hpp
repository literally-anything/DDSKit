#pragma once

#include "types.hpp"
#include <memory>
#include <string>
#include <fastdds/dds/domain/DomainParticipant.hpp>
#include <fastdds/dds/domain/DomainParticipantFactory.hpp>
#include <fastdds/dds/domain/qos/DomainParticipantQos.hpp>
#include <fastdds/dds/domain/DomainParticipantListener.hpp>
#include <fastdds/dds/core/status/StatusMask.hpp>

typedef fastdds::DomainParticipantListener _DomainParticipantListener;

namespace _DomainParticipant {
    typedef fastdds::DomainParticipant DomainParticipant;
    typedef fastdds::DomainParticipantFactory DomainParticipantFactory;
    typedef fastdds::DomainParticipantQos DomainParticipantQos;

    bool compareQos(DomainParticipantQos rhs, DomainParticipantQos lhs);

    class Listener : public _DomainParticipantListener {
    public:
        void *context = nullptr;

        bool(*onParticipantDiscovery)(void *context, DomainParticipant *participant, fastrtps::ParticipantDiscoveryStatus reason, fastdds::ParticipantBuiltinTopicData &&info) = nullptr;
        bool(*onDataReaderDiscovery)(void *context, DomainParticipant *participant, fastrtps::ReaderDiscoveryStatus reason, fastdds::SubscriptionBuiltinTopicData &&info) = nullptr;
        bool(*onDataWriterDiscovery)(void *context, DomainParticipant *participant, fastrtps::WriterDiscoveryStatus reason, fastdds::PublicationBuiltinTopicData &&info) = nullptr;

        void on_participant_discovery(DomainParticipant *participant,
                                      fastrtps::ParticipantDiscoveryStatus reason,
                                      const fastdds::ParticipantBuiltinTopicData &info,
                                      bool &should_be_ignored) override;
        void on_data_reader_discovery(DomainParticipant *participant,
                                      fastrtps::ReaderDiscoveryStatus reason,
                                      const fastdds::SubscriptionBuiltinTopicData &info,
                                      bool &should_be_ignored) override;
        void on_data_writer_discovery(DomainParticipant *participant,
                                      fastrtps::WriterDiscoveryStatus reason,
                                      const fastdds::PublicationBuiltinTopicData &info,
                                      bool &should_be_ignored) override;
                                      
    };

    Listener *createListener();
    void destroyListener(Listener *listener);
    void setListenerContext(Listener *listener, void *context);
    void setListenerParticipantDiscoveryCallback(Listener *listener,
                                                 bool(*onParticipantDiscovery)(void *context, DomainParticipant *participant, fastrtps::ParticipantDiscoveryStatus reason, fastdds::ParticipantBuiltinTopicData &&info));
    void setListenerDataReaderDiscoveryCallback(Listener *listener,
                                                bool(*onDataReaderDiscovery)(void *context, DomainParticipant *participant, fastrtps::ReaderDiscoveryStatus reason, fastdds::SubscriptionBuiltinTopicData &&info));
    void setListenerDataWriterDiscoveryCallback(Listener *listener,
                                                bool(*onDataWriterDiscovery)(void *context, DomainParticipant *participant, fastrtps::WriterDiscoveryStatus reason, fastdds::PublicationBuiltinTopicData &&info));
    
    inline DomainParticipantFactory *getFactory();

    _ReturnCode loadProfiles();
    DomainParticipantQos getDefaultQos();

    DomainParticipant *create(_DomainId domain, const std::string &profile);
    DomainParticipant *create(_DomainId domain, const DomainParticipantQos &qos);
    _ReturnCode destroy(DomainParticipant *participant);
    _ReturnCode destroyEntities(DomainParticipant *participant);

    DomainParticipantQos getQos(DomainParticipant *participant);
    _ReturnCode setQos(DomainParticipant *participant, const DomainParticipantQos qos);
    _ReturnCode setListener(DomainParticipant *participant, Listener *listener, const _StatusMask &mask);

    _ReturnCode registerType(DomainParticipant *participant,
                             _TypeSupport type, const std::string &name);
}
