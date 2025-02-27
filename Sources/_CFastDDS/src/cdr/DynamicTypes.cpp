/*
 * DynamicTypes.cpp
 * src
 * 
 * Created by Hunter Baker on 8/19/2024
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#include "cdr/DynamicTypes.hpp"

#include <fastdds/dds/core/Types.hpp>
#include <fastdds/dds/core/detail/DDSReturnCode.hpp>
#include <fastdds/dds/xtypes/dynamic_types/Types.hpp>
#include <fastdds/dds/xtypes/dynamic_types/detail/type_traits.hpp>

namespace FastDDS {
    namespace DynamicTypes {
        typedef epfastdds::MemberDescriptor::_ref_type MemberDescriptor;

        DynamicDataContainer::DynamicDataContainer(const DynamicTypeContainer &type) {
            data = epfastdds::DynamicDataFactory::get_instance()->create_data(type.type);
        }
        DynamicDataContainer::DynamicDataContainer(const DynamicDataContainer &other) {
            // data = other.data->clone();
            data = other.data;
        }
        bool DynamicDataContainer::equals(const DynamicDataContainer &other) const {
            return data->equals(other.data);
        }
        DynamicDataContainer::DynamicDataContainer(const DynamicData &data) {
            this->data = data;
        }

        inline MemberDescriptor createMemberDescriptor() {
            return epfastdds::traits<epfastdds::MemberDescriptor>::make_shared();
        }

        DynamicTypeBuilder createStruct(bool &success, const char * _Nonnull name) {
            TypeDescriptor descriptor = epfastdds::traits<epfastdds::TypeDescriptor>::make_shared();

            descriptor->kind(epfastdds::TK_STRUCTURE);
            descriptor->name(name);

            DynamicTypeBuilder builder = epfastdds::DynamicTypeBuilderFactory::get_instance()->create_type(descriptor);
            success = builder != nullptr;

            return builder;
        }

        DDSReturnCode createBool(const DynamicTypeBuilder &builder, const char * _Nonnull name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_BOOLEAN));
            return builder->add_member(member);
        }
        DDSReturnCode createInt8(const DynamicTypeBuilder &builder, const char * _Nonnull name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_INT8));
            return builder->add_member(member);
        }
        DDSReturnCode createUInt8(const DynamicTypeBuilder &builder, const char * _Nonnull name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_UINT8));
            return builder->add_member(member);
        }
        DDSReturnCode createInt16(const DynamicTypeBuilder &builder, const char * _Nonnull name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_INT16));
            return builder->add_member(member);
        }
        DDSReturnCode createUInt16(const DynamicTypeBuilder &builder, const char * _Nonnull name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_UINT16));
            return builder->add_member(member);
        }
        DDSReturnCode createInt32(const DynamicTypeBuilder &builder, const char * _Nonnull name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_INT32));
            return builder->add_member(member);
        }
        DDSReturnCode createUInt32(const DynamicTypeBuilder &builder, const char * _Nonnull name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_UINT32));
            return builder->add_member(member);
        }
        DDSReturnCode createInt64(const DynamicTypeBuilder &builder, const char * _Nonnull name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_INT64));
            return builder->add_member(member);
        }
        DDSReturnCode createUInt64(const DynamicTypeBuilder &builder, const char * _Nonnull name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_UINT64));
            return builder->add_member(member);
        }
        DDSReturnCode createFloat32(const DynamicTypeBuilder &builder, const char * _Nonnull name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_FLOAT32));
            return builder->add_member(member);
        }
        DDSReturnCode createFloat64(const DynamicTypeBuilder &builder, const char * _Nonnull name) {
            MemberDescriptor member = createMemberDescriptor();
            member->name(name);
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->get_primitive_type(epfastdds::TK_FLOAT64));
            return builder->add_member(member);
        }
        DDSReturnCode createString(const DynamicTypeBuilder &builder, const char * _Nonnull name) {
            return createString(builder, name, epfastdds::LENGTH_UNLIMITED);
        }
        DDSReturnCode createString(const DynamicTypeBuilder &builder, const char * _Nonnull name, uint32_t length) {
            MemberDescriptor member = createMemberDescriptor();
            member->name("message");
            member->type(epfastdds::DynamicTypeBuilderFactory::get_instance()->create_string_type(length)->build());
            return builder->add_member(member);
        }

        DynamicTypeContainer buildType(const DynamicTypeBuilder &builder) {
            epfastdds::traits<epfastdds::DynamicType>::ref_type type = builder->build();
            return DynamicTypeContainer(type);
        }
        TypeSupportWrapper buildTypeSupport(const DynamicTypeContainer &type) {
            epfastdds::DynamicPubSubType *pubSubType = new epfastdds::DynamicPubSubType(type.type);
            pubSubType->register_type_object_representation();
            return TypeSupportWrapper(TypeSupport(pubSubType));
        }

        bool getBool(const DynamicDataContainer &data, epfastdds::MemberId memberId) {
            bool value;
            data.data->get_boolean_value(value, memberId);
            return value;
        }
        int8_t getInt8(const DynamicDataContainer &data, epfastdds::MemberId memberId) {
            int8_t value;
            data.data->get_int8_value(value, memberId);
            return value;
        }
        uint8_t getUInt8(const DynamicDataContainer &data, epfastdds::MemberId memberId) {
            uint8_t value;
            data.data->get_uint8_value(value, memberId);
            return value;
        }
        int16_t getInt16(const DynamicDataContainer &data, epfastdds::MemberId memberId) {
            int16_t value;
            data.data->get_int16_value(value, memberId);
            return value;
        }
        uint16_t getUInt16(const DynamicDataContainer &data, epfastdds::MemberId memberId) {
            uint16_t value;
            data.data->get_uint16_value(value, memberId);
            return value;
        }
        int32_t getInt32(const DynamicDataContainer &data, epfastdds::MemberId memberId) {
            int32_t value;
            data.data->get_int32_value(value, memberId);
            return value;
        }
        uint32_t getUInt32(const DynamicDataContainer &data, epfastdds::MemberId memberId) {
            uint32_t value;
            data.data->get_uint32_value(value, memberId);
            return value;
        }
        int64_t getInt64(const DynamicDataContainer &data, epfastdds::MemberId memberId) {
            int64_t value;
            data.data->get_int64_value(value, memberId);
            return value;
        }
        uint64_t getUInt64(const DynamicDataContainer &data, epfastdds::MemberId memberId) {
            uint64_t value;
            data.data->get_uint64_value(value, memberId);
            return value;
        }
        float_t getFloat32(const DynamicDataContainer &data, epfastdds::MemberId memberId) {
            float_t value;
            data.data->get_float32_value(value, memberId);
            return value;
        }
        double_t getFloat64(const DynamicDataContainer &data, epfastdds::MemberId memberId) {
            double_t value;
            data.data->get_float64_value(value, memberId);
            return value;
        }
        std::string getString(const DynamicDataContainer &data, epfastdds::MemberId memberId) {
            std::string value;
            data.data->get_string_value(value, memberId);
            return value;
        }

        void setBool(const DynamicDataContainer &data, epfastdds::MemberId memberId, bool value) {
            data.data->set_boolean_value(memberId, value);
        }
        void setInt8(const DynamicDataContainer &data, epfastdds::MemberId memberId, int8_t value) {
            data.data->set_int8_value(memberId, value);
        }
        void setUInt8(const DynamicDataContainer &data, epfastdds::MemberId memberId, uint8_t value) {
            data.data->set_uint8_value(memberId, value);
        }
        void setInt16(const DynamicDataContainer &data, epfastdds::MemberId memberId, int16_t value) {
            data.data->set_int16_value(memberId, value);
        }
        void setUInt16(const DynamicDataContainer &data, epfastdds::MemberId memberId, uint16_t value) {
            data.data->set_uint16_value(memberId, value);
        }
        void setInt32(const DynamicDataContainer &data, epfastdds::MemberId memberId, int32_t value) {
            data.data->set_int32_value(memberId, value);
        }
        void setUInt32(const DynamicDataContainer &data, epfastdds::MemberId memberId, uint32_t value) {
            data.data->set_uint32_value(memberId, value);
        }
        void setInt64(const DynamicDataContainer &data, epfastdds::MemberId memberId, int64_t value) {
            data.data->set_int64_value(memberId, value);
        }
        void setUInt64(const DynamicDataContainer &data, epfastdds::MemberId memberId, uint64_t value) {
            data.data->set_uint64_value(memberId, value);
        }
        void setFloat32(const DynamicDataContainer &data, epfastdds::MemberId memberId, float_t value) {
            data.data->set_float32_value(memberId, value);
        }
        void setFloat64(const DynamicDataContainer &data, epfastdds::MemberId memberId, double_t value) {
            data.data->set_float64_value(memberId, value);
        }
        void setString(const DynamicDataContainer &data, epfastdds::MemberId memberId, const std::string &value) {
            data.data->set_string_value(memberId, value);
        }
    }
}
