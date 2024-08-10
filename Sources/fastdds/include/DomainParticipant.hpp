#pragma once

#include <memory>
#include <string>

#include "types.hpp"
#include "../../../.compatibility-headers/DDSKitInternal-Swift.h"

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
    private:
        DDSKitInternal::ParticipantCallbacks *callbacks;

    public:
        explicit Listener(DDSKitInternal::ParticipantCallbacks *callbacks);

        void on_participant_discovery(DomainParticipant *participant,
                                      fastrtps::ParticipantDiscoveryStatus reason,
                                      const fastdds::ParticipantBuiltinTopicData &info,
                                      bool &should_be_ignored) override;        
    };

    Listener *createListener(DDSKitInternal::ParticipantCallbacks *callbacks);
    void destroyListener(Listener *listener);
    
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
    _DomainId getDomainId(DomainParticipant *participant);

    _ReturnCode registerType(DomainParticipant *participant,
                             _TypeSupport type, const std::string &name);
}
