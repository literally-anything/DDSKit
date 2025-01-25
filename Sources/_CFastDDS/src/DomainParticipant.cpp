/*
 * DomainParticipant.cpp
 * src
 * 
 * Created by Hunter Baker on 8/01/2024
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#include "old/DomainParticipant.hpp"
#include "old/HelloWorldPubSubTypes.hpp"
#include "old/DynamicTypes.hpp"

#include <fastdds/dds/xtypes/dynamic_types/DynamicTypeBuilderFactory.hpp>
#include <fastdds/dds/xtypes/dynamic_types/DynamicTypeBuilder.hpp>
// #include <fastdds/dds/xtypes/dynamic_types/DynamicTypeMember.hpp>
// #include <fastdds/dds/xtypes/dynamic_types/DynamicData.hpp>
// #include <fastdds/dds/xtypes/dynamic_types/DynamicDataFactory.hpp>
#include <fastdds/dds/xtypes/dynamic_types/DynamicPubSubType.hpp>

namespace fastdds {
    namespace _DomainParticipant {
        bool compareQos(DomainParticipantQos rhs, DomainParticipantQos lhs) {
            return rhs == lhs;
        }

        Listener::Listener(_FastDDSHelpers::ParticipantCallbacks *callbacks) : callbacks(callbacks) {}
        void Listener::on_participant_discovery(DomainParticipant *participant,
                                                epfastrtps::ParticipantDiscoveryStatus reason,
                                                const DDSParticipantBuiltinTopicData &info,
                                                bool &should_be_ignored) {
            callbacks->participantDiscovered(participant, &reason, &info);
        }

        Listener *createListener(_FastDDSHelpers::ParticipantCallbacks *callbacks) {
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
            // _DynamicTypes::TypeDescriptor descriptor = epfastdds::traits<epfastdds::TypeDescriptor>::make_shared();
            // descriptor->kind(epfastdds::TK_STRUCTURE);
            // descriptor->name("ty");
            // auto builder = epfastdds::DynamicTypeBuilderFactory::get_instance()->create_type(descriptor);

            // epfastdds::MemberDescriptor::_ref_type member = epfastdds::traits<epfastdds::MemberDescriptor>::make_shared();
            // member->name("index");
            // member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_UINT32));
            // builder->add_member(member);

            // epfastdds::traits<epfastdds::DynamicType>::ref_type t = builder->build();
            // epfastdds::DynamicPubSubType *pubSubType = new epfastdds::DynamicPubSubType(t);
            // pubSubType->register_type_object_representation();
            // _TypeSupport(pubSubType)

            return participant->register_type(type, name);
        }
    }
}
