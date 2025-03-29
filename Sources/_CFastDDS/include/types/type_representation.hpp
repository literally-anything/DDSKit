/*
 * type_representation.hpp
 * include
 * 
 * Created by Hunter Baker on 1/24/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#if __has_include(<swift/bridging>)
# include <swift/bridging>
#else
# include "utils/swift_bridging.h"
#endif

#include "common.h"

#include <fastcdr/xcdr/optional.hpp>
#include <fastdds/dds/domain/DomainParticipantFactory.hpp>
#include <fastdds/dds/log/Log.hpp>

namespace FastDDS {

    namespace Types {

        namespace fastddsxtypes = eprosima::fastdds::dds::xtypes;

        using eprosima::fastcdr::optional;
        using fastddsxtypes::TypeIdentifier;
        using fastddsxtypes::CompleteStructType;

        class CreateInfo final {
        public:
            INLINE CreateInfo() : struct_flags(), header(), member_seq(), type_ann_builtin(), ann_custom(), tmp_ann_custom() {}

            fastddsxtypes::StructTypeFlag struct_flags;
            fastddsxtypes::CompleteStructHeader header;
            fastddsxtypes::CompleteStructMemberSeq member_seq;
            optional<fastddsxtypes::AppliedBuiltinTypeAnnotations> type_ann_builtin;
            optional<fastddsxtypes::AppliedAnnotationSeq> ann_custom;
            fastddsxtypes::AppliedAnnotationSeq tmp_ann_custom;
        };

        class TypeIdentifierPair final {
        public:
            INLINE TypeIdentifierPair() : pair() {}
            INLINE TypeIdentifierPair(fastddsxtypes::TypeIdentifierPair pair) : pair(pair) {}
            INLINE TypeIdentifierPair(const TypeIdentifierPair &other) : pair(other.pair) {}

            fastddsxtypes::TypeIdentifierPair pair;
        };

        NODISCARD bool getIdentifiersForName(
            const std::string &name, TypeIdentifierPair &typeIdentifiers
        ) SWIFT_NAME(getIdentifiersForName(name:identifiers:));

        NODISCARD bool createStruct(
            const std::string &name, CreateInfo &info
        ) SWIFT_NAME(createStruct(name:info:));
        NODISCARD bool addStructMember(
            CreateInfo &info,
            const TypeIdentifierPair &memberIdentifiers,
            const std::string &name, uint32_t id, bool isOptional, bool isKey
        ) SWIFT_NAME(addStructMember(info:identifiers:name:id:isOptional:isKey:));
        NODISCARD eprosima::fastdds::dds::ReturnCode_t finishStruct(
            const CreateInfo &info, const std::string &name, TypeIdentifierPair &identifiers
        ) SWIFT_NAME(finishStruct(info:name:identifiers:));

        NODISCARD bool createString(
            const std::string &name, bool isWide, TypeIdentifierPair &identifiers
        ) SWIFT_NAME(createString(name:isWide:identifiers:));

        NODISCARD bool createArray(
            const std::string &name, std::vector<uint8_t> shape, const TypeIdentifierPair &elementIdentifiers, TypeIdentifierPair &identifiers
        ) SWIFT_NAME(createArray(name:shape:element:identifiers:));
        NODISCARD bool createArray(
            const std::string &name, std::vector<uint32_t> shape, const TypeIdentifierPair &elementIdentifiers, TypeIdentifierPair &identifiers
        ) SWIFT_NAME(createArray(name:shape:element:identifiers:));

        NODISCARD bool createSequence(
            const std::string &name, const TypeIdentifierPair &elementIdentifiers, TypeIdentifierPair &identifiers
        ) SWIFT_NAME(createSequence(name:element:identifiers:));

        NODISCARD bool createMap(
            const std::string &name, const TypeIdentifierPair &keyIdentifiers, const TypeIdentifierPair &valueIdentifiers, TypeIdentifierPair &identifiers
        ) SWIFT_NAME(createMap(name:key:value:identifiers:));

    }

}
