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

namespace fastdds {
    typedef epfastrtps::ParticipantDiscoveryStatus DDSParticipantDiscoveryStatus;
    typedef epfastdds::ParticipantBuiltinTopicData DDSParticipantBuiltinTopicData;

    typedef epfastdds::DomainParticipantListener _DomainParticipantListener;

    namespace _DomainParticipant {
        typedef epfastdds::DomainParticipant DomainParticipant;
        typedef epfastdds::DomainParticipantFactory DomainParticipantFactory;
        typedef epfastdds::DomainParticipantQos DomainParticipantQos;

        bool compareQos(DomainParticipantQos rhs, DomainParticipantQos lhs);

        class Listener : public _DomainParticipantListener {
        private:
            DDSKitInternal::ParticipantCallbacks *callbacks;

        public:
            explicit Listener(DDSKitInternal::ParticipantCallbacks *callbacks);

            void on_participant_discovery(DomainParticipant *participant,
                                        DDSParticipantDiscoveryStatus reason,
                                        const DDSParticipantBuiltinTopicData &info,
                                        bool &should_be_ignored) override;        
        };

        Listener *createListener(DDSKitInternal::ParticipantCallbacks *callbacks);
        void destroyListener(Listener *listener);
        
        inline DomainParticipantFactory *getFactory();

        DDSReturnCode loadProfiles();
        DomainParticipantQos getDefaultQos();

        DomainParticipant *create(DDSDomainId domain, const std::string &profile);
        DomainParticipant *create(DDSDomainId domain, const DomainParticipantQos &qos);
        DDSReturnCode destroy(DomainParticipant *participant);
        DDSReturnCode destroyEntities(DomainParticipant *participant);

        DomainParticipantQos getQos(DomainParticipant *participant);
        DDSReturnCode setQos(DomainParticipant *participant, const DomainParticipantQos qos);
        DDSReturnCode setListener(DomainParticipant *participant, Listener *listener, const _StatusMask &mask);
        DDSDomainId getDomainId(DomainParticipant *participant);

        DDSReturnCode registerType(DomainParticipant *participant,
                                   _TypeSupport type, const std::string &name);
    }
}
