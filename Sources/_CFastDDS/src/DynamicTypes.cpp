/*
 * DynamicTypes.cpp
 * src
 * 
 * Created by Hunter Baker on 8/19/2024
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#include "old/DynamicTypes.hpp"

#include <fastdds/dds/core/Types.hpp>
#include <fastdds/dds/core/detail/DDSReturnCode.hpp>
#include <fastdds/dds/xtypes/dynamic_types/DynamicData.hpp>
#include <fastdds/dds/xtypes/dynamic_types/DynamicTypeBuilderFactory.hpp>
#include <fastdds/dds/xtypes/dynamic_types/DynamicTypeBuilder.hpp>
// #include <fastdds/dds/xtypes/dynamic_types/DynamicTypeMember.hpp>
// #include <fastdds/dds/xtypes/dynamic_types/DynamicData.hpp>
#include <fastdds/dds/xtypes/dynamic_types/DynamicDataFactory.hpp>
#include <fastdds/dds/xtypes/dynamic_types/DynamicPubSubType.hpp>
#include <fastdds/dds/xtypes/dynamic_types/Types.hpp>
#include <fastdds/dds/xtypes/dynamic_types/detail/type_traits.hpp>

namespace fastdds {
    namespace _DynamicTypes {
        typedef epfastdds::MemberDescriptor::_ref_type MemberDescriptor;

        inline MemberDescriptor createMemberDescriptor() {
            return epfastdds::traits<epfastdds::MemberDescriptor>::make_shared();
        }

        DynamicTypeBuilder createStruct(bool &success, const char *name) {
            TypeDescriptor descriptor = epfastdds::traits<epfastdds::TypeDescriptor>::make_shared();

            descriptor->kind(epfastdds::TK_STRUCTURE);
            descriptor->name(name);

            DynamicTypeBuilder builder = epfastdds::DynamicTypeBuilderFactory::get_instance()->create_type(descriptor);
            success = builder != nullptr;

            return builder;
        }

        DDSReturnCode createBool(DynamicTypeBuilder builder, const char *name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_BOOLEAN));
            return builder->add_member(member);
        }
        DDSReturnCode createInt8(DynamicTypeBuilder builder, const char *name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_INT8));
            return builder->add_member(member);
        }
        DDSReturnCode createUInt8(DynamicTypeBuilder builder, const char *name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_UINT8));
            return builder->add_member(member);
        }
        DDSReturnCode createInt16(DynamicTypeBuilder builder, const char *name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_INT16));
            return builder->add_member(member);
        }
        DDSReturnCode createUInt16(DynamicTypeBuilder builder, const char *name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_UINT16));
            return builder->add_member(member);
        }
        DDSReturnCode createInt32(DynamicTypeBuilder builder, const char *name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_INT32));
            return builder->add_member(member);
        }
        DDSReturnCode createUInt32(DynamicTypeBuilder builder, const char *name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_UINT32));
            return builder->add_member(member);
        }
        DDSReturnCode createInt64(DynamicTypeBuilder builder, const char *name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_INT64));
            return builder->add_member(member);
        }
        DDSReturnCode createUInt64(DynamicTypeBuilder builder, const char *name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_UINT64));
            return builder->add_member(member);
        }
        DDSReturnCode createFloat32(DynamicTypeBuilder builder, const char *name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_FLOAT32));
            return builder->add_member(member);
        }
        DDSReturnCode createFloat64(DynamicTypeBuilder builder, const char *name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_FLOAT64));
            return builder->add_member(member);
        }
        DDSReturnCode createString(DynamicTypeBuilder builder, const char *name) {
            return createString(builder, name, epfastdds::LENGTH_UNLIMITED);
        }
        DDSReturnCode createString(DynamicTypeBuilder builder, const char *name, uint32_t length) {
            MemberDescriptor member = createMemberDescriptor();
            member->name("message");
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->create_string_type(length)->build());
            return builder->add_member(member);
        }

        DynamicTypeContainer buildType(DynamicTypeBuilder builder) {
            epfastdds::traits<epfastdds::DynamicType>::ref_type type = builder->build();
            return DynamicTypeContainer(type);
        }
        _TypeSupport buildTypeSupport(DynamicTypeContainer type) {
            epfastdds::DynamicPubSubType *pubSubType = new epfastdds::DynamicPubSubType(type.type);
            pubSubType->register_type_object_representation();
            return _TypeSupport(pubSubType);
        }
        DynamicData buildData(DynamicTypeContainer type) {
            return epfastdds::DynamicDataFactory::get_instance()->create_data(type.type);
        }

        bool dataEqual(DynamicData lhs, DynamicData rhs) {
            return lhs->equals(rhs);
        }

        bool getBool(DynamicData data, epfastdds::MemberId memberId) {
            bool value;
            data->get_boolean_value(value, memberId);
            return value;
        }
        int8_t getInt8(DynamicData data, epfastdds::MemberId memberId) {
            int8_t value;
            data->get_int8_value(value, memberId);
            return value;
        }
        uint8_t getUInt8(DynamicData data, epfastdds::MemberId memberId) {
            uint8_t value;
            data->get_uint8_value(value, memberId);
            return value;
        }
        int16_t getInt16(DynamicData data, epfastdds::MemberId memberId) {
            int16_t value;
            data->get_int16_value(value, memberId);
            return value;
        }
        uint16_t getUInt16(DynamicData data, epfastdds::MemberId memberId) {
            uint16_t value;
            data->get_uint16_value(value, memberId);
            return value;
        }
        int32_t getInt32(DynamicData data, epfastdds::MemberId memberId) {
            int32_t value;
            data->get_int32_value(value, memberId);
            return value;
        }
        uint32_t getUInt32(DynamicData data, epfastdds::MemberId memberId) {
            uint32_t value;
            data->get_uint32_value(value, memberId);
            return value;
        }
        int64_t getInt64(DynamicData data, epfastdds::MemberId memberId) {
            int64_t value;
            data->get_int64_value(value, memberId);
            return value;
        }
        uint64_t getUInt64(DynamicData data, epfastdds::MemberId memberId) {
            uint64_t value;
            data->get_uint64_value(value, memberId);
            return value;
        }
        float_t getFloat32(DynamicData data, epfastdds::MemberId memberId) {
            float_t value;
            data->get_float32_value(value, memberId);
            return value;
        }
        double_t getFloat64(DynamicData data, epfastdds::MemberId memberId) {
            double_t value;
            data->get_float64_value(value, memberId);
            return value;
        }
        std::string getString(DynamicData data, epfastdds::MemberId memberId) {
            std::string value;
            data->get_string_value(value, memberId);
            return value;
        }
        DynamicData getComplex(DynamicData data, epfastdds::MemberId memberId) {
            DynamicData value;
            data->get_complex_value(value, memberId);
            return value;
        }

        void setBool(DynamicData data, epfastdds::MemberId memberId, bool value) {
            data->set_boolean_value(memberId, value);
        }
        void setInt8(DynamicData data, epfastdds::MemberId memberId, int8_t value) {
            data->set_int8_value(memberId, value);
        }
        void setUInt8(DynamicData data, epfastdds::MemberId memberId, uint8_t value) {
            data->set_uint8_value(memberId, value);
        }
        void setInt16(DynamicData data, epfastdds::MemberId memberId, int16_t value) {
            data->set_int16_value(memberId, value);
        }
        void setUInt16(DynamicData data, epfastdds::MemberId memberId, uint16_t value) {
            data->set_uint16_value(memberId, value);
        }
        void setInt32(DynamicData data, epfastdds::MemberId memberId, int32_t value) {
            data->set_int32_value(memberId, value);
        }
        void setUInt32(DynamicData data, epfastdds::MemberId memberId, uint32_t value) {
            data->set_uint32_value(memberId, value);
        }
        void setInt64(DynamicData data, epfastdds::MemberId memberId, int64_t value) {
            data->set_int64_value(memberId, value);
        }
        void setUInt64(DynamicData data, epfastdds::MemberId memberId, uint64_t value) {
            data->set_uint64_value(memberId, value);
        }
        void setFloat32(DynamicData data, epfastdds::MemberId memberId, float_t value) {
            data->set_float32_value(memberId, value);
        }
        void setFloat64(DynamicData data, epfastdds::MemberId memberId, double_t value) {
            data->set_float64_value(memberId, value);
        }
        void setString(DynamicData data, epfastdds::MemberId memberId, const std::string &value) {
            data->set_string_value(memberId, value);
        }
        void setComplex(DynamicData data, epfastdds::MemberId memberId, DynamicData value) {
            data->set_complex_value(memberId, value);
        }
    }
}
