#pragma once

#include "types.hpp"

#include <cmath>
#include <cstdint>
#include <fastdds/dds/xtypes/dynamic_types/detail/dynamic_language_binding.hpp>
#include <tuple>

#include <fastdds/dds/xtypes/dynamic_types/DynamicType.hpp>
#include <fastdds/dds/xtypes/dynamic_types/DynamicTypeBuilder.hpp>
#include <fastdds/dds/xtypes/dynamic_types/DynamicTypeBuilderFactory.hpp>
#include <fastdds/dds/xtypes/dynamic_types/DynamicDataFactory.hpp>
#include <fastdds/dds/xtypes/dynamic_types/DynamicPubSubType.hpp>
#include <fastdds/dds/xtypes/dynamic_types/MemberDescriptor.hpp>

#include "DomainParticipant.hpp"

namespace fastdds {
    namespace _DynamicTypes {
        typedef epfastdds::DynamicTypeBuilder::_ref_type DynamicTypeBuilder;
        typedef epfastdds::TypeDescriptor::_ref_type TypeDescriptor;
        typedef epfastdds::DynamicType::_ref_type DynamicType;
        typedef epfastdds::DynamicData::_ref_type DynamicData;

        class DynamicTypeContainer {
        public:
            DynamicType type;

            DynamicTypeContainer(DynamicType type) : type(type) {}
        };

        DynamicTypeBuilder createStruct(bool &success, const char *name);

        DDSReturnCode createBool(DynamicTypeBuilder builder, const char *name);
        DDSReturnCode createInt8(DynamicTypeBuilder builder, const char *name);
        DDSReturnCode createUInt8(DynamicTypeBuilder builder, const char *name);
        DDSReturnCode createInt16(DynamicTypeBuilder builder, const char *name);
        DDSReturnCode createUInt16(DynamicTypeBuilder builder, const char *name);
        DDSReturnCode createInt32(DynamicTypeBuilder builder, const char *name);
        DDSReturnCode createUInt32(DynamicTypeBuilder builder, const char *name);
        DDSReturnCode createInt64(DynamicTypeBuilder builder, const char *name);
        DDSReturnCode createUInt64(DynamicTypeBuilder builder, const char *name);
        DDSReturnCode createFloat32(DynamicTypeBuilder builder, const char *name);
        DDSReturnCode createFloat64(DynamicTypeBuilder builder, const char *name);
        DDSReturnCode createString(DynamicTypeBuilder builder, const char *name);
        DDSReturnCode createString(DynamicTypeBuilder builder, const char *name, uint32_t length);

        DynamicTypeContainer buildType(DynamicTypeBuilder builder);
        _TypeSupport buildTypeSupport(DynamicTypeContainer type);
        DynamicData buildData(DynamicTypeContainer type);

        bool dataEqual(DynamicData lhs, DynamicData rhs);

        bool getBool(DynamicData data, epfastdds::MemberId memberId);
        int8_t getInt8(DynamicData data, epfastdds::MemberId memberId);
        uint8_t getUInt8(DynamicData data, epfastdds::MemberId memberId);
        int16_t getInt16(DynamicData data, epfastdds::MemberId memberId);
        uint16_t getUInt16(DynamicData data, epfastdds::MemberId memberId);
        int32_t getInt32(DynamicData data, epfastdds::MemberId memberId);
        uint32_t getUInt32(DynamicData data, epfastdds::MemberId memberId);
        int64_t getInt64(DynamicData data, epfastdds::MemberId memberId);
        uint64_t getUInt64(DynamicData data, epfastdds::MemberId memberId);
        float_t getFloat32(DynamicData data, epfastdds::MemberId memberId);
        double_t getFloat64(DynamicData data, epfastdds::MemberId memberId);
        std::string getString(DynamicData data, epfastdds::MemberId memberId);

        void setBool(DynamicData data, epfastdds::MemberId memberId, bool value);
        void setInt8(DynamicData data, epfastdds::MemberId memberId, int8_t value);
        void setUInt8(DynamicData data, epfastdds::MemberId memberId, uint8_t value);
        void setInt16(DynamicData data, epfastdds::MemberId memberId, int16_t value);
        void setUInt16(DynamicData data, epfastdds::MemberId memberId, uint16_t value);
        void setInt32(DynamicData data, epfastdds::MemberId memberId, int32_t value);
        void setUInt32(DynamicData data, epfastdds::MemberId memberId, uint32_t value);
        void setInt64(DynamicData data, epfastdds::MemberId memberId, int64_t value);
        void setUInt64(DynamicData data, epfastdds::MemberId memberId, uint64_t value);
        void setFloat32(DynamicData data, epfastdds::MemberId memberId, float_t value);
        void setFloat64(DynamicData data, epfastdds::MemberId memberId, double_t value);
        void setString(DynamicData data, epfastdds::MemberId memberId, const std::string &value);
    }
}
