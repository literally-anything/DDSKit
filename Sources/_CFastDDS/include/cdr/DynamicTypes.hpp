/*
 * DynamicTypes.hpp
 * include
 * 
 * Created by Hunter Baker on 8/19/2024
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <cmath>
#include <cstdint>

#include "type_support.hpp"

#include <fastdds/dds/xtypes/dynamic_types/DynamicData.hpp>
#include <fastdds/dds/xtypes/dynamic_types/DynamicType.hpp>
#include <fastdds/dds/xtypes/dynamic_types/DynamicTypeBuilder.hpp>
#include <fastdds/dds/xtypes/dynamic_types/DynamicTypeBuilderFactory.hpp>
#include <fastdds/dds/xtypes/dynamic_types/DynamicDataFactory.hpp>
#include <fastdds/dds/xtypes/dynamic_types/DynamicPubSubType.hpp>
#include <fastdds/dds/xtypes/dynamic_types/MemberDescriptor.hpp>
#include <fastdds/dds/xtypes/dynamic_types/detail/dynamic_language_binding.hpp>

namespace epfastdds = eprosima::fastdds::dds;
using namespace eprosima::fastdds::dds;
typedef eprosima::fastdds::dds::ReturnCode_t DDSReturnCode;

namespace FastDDS {
    namespace DynamicTypes {
        typedef epfastdds::DynamicTypeBuilder::_ref_type DynamicTypeBuilder;
        typedef epfastdds::TypeDescriptor::_ref_type TypeDescriptor;
        typedef epfastdds::DynamicType::_ref_type DynamicType;
        typedef epfastdds::DynamicData::_ref_type DynamicData;

        class DynamicTypeContainer {
        public:
            DynamicType type;

            DynamicTypeContainer(DynamicType type) : type(type) {}
        };

        class DynamicDataContainer {
        public:
            DynamicData data;

            DynamicDataContainer(const DynamicTypeContainer &type);
            DynamicDataContainer(const DynamicDataContainer &other);
            DynamicDataContainer(const DynamicData &data);

            bool equals(const DynamicDataContainer &other) const;
        };

        DynamicTypeBuilder createStruct(bool &success, const char * _Nonnull name);

        DDSReturnCode createBool(const DynamicTypeBuilder &builder, const char * _Nonnull name);
        DDSReturnCode createInt8(const DynamicTypeBuilder &builder, const char * _Nonnull name);
        DDSReturnCode createUInt8(const DynamicTypeBuilder &builder, const char * _Nonnull name);
        DDSReturnCode createInt16(const DynamicTypeBuilder &builder, const char * _Nonnull name);
        DDSReturnCode createUInt16(const DynamicTypeBuilder &builder, const char * _Nonnull name);
        DDSReturnCode createInt32(const DynamicTypeBuilder &builder, const char * _Nonnull name);
        DDSReturnCode createUInt32(const DynamicTypeBuilder &builder, const char * _Nonnull name);
        DDSReturnCode createInt64(const DynamicTypeBuilder &builder, const char * _Nonnull name);
        DDSReturnCode createUInt64(const DynamicTypeBuilder &builder, const char * _Nonnull name);
        DDSReturnCode createFloat32(const DynamicTypeBuilder &builder, const char * _Nonnull name);
        DDSReturnCode createFloat64(const DynamicTypeBuilder &builder, const char * _Nonnull name);
        DDSReturnCode createString(const DynamicTypeBuilder &builder, const char * _Nonnull name);
        DDSReturnCode createString(const DynamicTypeBuilder &builder, const char * _Nonnull name, uint32_t length);

        DynamicTypeContainer buildType(const DynamicTypeBuilder &builder);
        TypeSupportWrapper buildTypeSupport(const DynamicTypeContainer &type);

        bool getBool(const DynamicDataContainer &data, epfastdds::MemberId memberId);
        int8_t getInt8(const DynamicDataContainer &data, epfastdds::MemberId memberId);
        uint8_t getUInt8(const DynamicDataContainer &data, epfastdds::MemberId memberId);
        int16_t getInt16(const DynamicDataContainer &data, epfastdds::MemberId memberId);
        uint16_t getUInt16(const DynamicDataContainer &data, epfastdds::MemberId memberId);
        int32_t getInt32(const DynamicDataContainer &data, epfastdds::MemberId memberId);
        uint32_t getUInt32(const DynamicDataContainer &data, epfastdds::MemberId memberId);
        int64_t getInt64(const DynamicDataContainer &data, epfastdds::MemberId memberId);
        uint64_t getUInt64(const DynamicDataContainer &data, epfastdds::MemberId memberId);
        float_t getFloat32(const DynamicDataContainer &data, epfastdds::MemberId memberId);
        double_t getFloat64(const DynamicDataContainer &data, epfastdds::MemberId memberId);
        std::string getString(const DynamicDataContainer &data, epfastdds::MemberId memberId);

        void setBool(const DynamicDataContainer &data, epfastdds::MemberId memberId, bool value);
        void setInt8(const DynamicDataContainer &data, epfastdds::MemberId memberId, int8_t value);
        void setUInt8(const DynamicDataContainer &data, epfastdds::MemberId memberId, uint8_t value);
        void setInt16(const DynamicDataContainer &data, epfastdds::MemberId memberId, int16_t value);
        void setUInt16(const DynamicDataContainer &data, epfastdds::MemberId memberId, uint16_t value);
        void setInt32(const DynamicDataContainer &data, epfastdds::MemberId memberId, int32_t value);
        void setUInt32(const DynamicDataContainer &data, epfastdds::MemberId memberId, uint32_t value);
        void setInt64(const DynamicDataContainer &data, epfastdds::MemberId memberId, int64_t value);
        void setUInt64(const DynamicDataContainer &data, epfastdds::MemberId memberId, uint64_t value);
        void setFloat32(const DynamicDataContainer &data, epfastdds::MemberId memberId, float_t value);
        void setFloat64(const DynamicDataContainer &data, epfastdds::MemberId memberId, double_t value);
        void setString(const DynamicDataContainer &data, epfastdds::MemberId memberId, const std::string &value);
    }
}
