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

#include <fastdds/dds/core/ReturnCode.hpp>
#include <fastdds/dds/xtypes/type_representation/detail/dds_xtypes_typeobject.hpp>

namespace FastDDS {

    namespace Types {

        namespace fastddsxtypes = eprosima::fastdds::dds::xtypes;
        
        using fastddsxtypes::TypeIdentifier;

        class StructCreateInfo final {
        public:
            INLINE StructCreateInfo() : struct_flags(), header(), member_seq() {}

            fastddsxtypes::StructTypeFlag struct_flags;
            fastddsxtypes::CompleteStructHeader header;
            fastddsxtypes::CompleteStructMemberSeq member_seq;
        };

        class UnionCreateInfo final {
        public:
            INLINE UnionCreateInfo() : union_flags(), header(), member_seq(), discriminator() {}

            fastddsxtypes::UnionTypeFlag union_flags;
            fastddsxtypes::CompleteUnionHeader header;
            fastddsxtypes::CompleteUnionMemberSeq member_seq;
            fastddsxtypes::CompleteDiscriminatorMember discriminator;
        };

        class TypeIdentifierPair final {
        public:
            INLINE TypeIdentifierPair() : pair() {}
            INLINE TypeIdentifierPair(fastddsxtypes::TypeIdentifierPair pair) : pair(pair) {}
            INLINE TypeIdentifierPair(const TypeIdentifierPair &other) : pair(other.pair) {}

            fastddsxtypes::TypeIdentifierPair pair;
        } SWIFT_UNCHECKED_SENDABLE;

        NODISCARD bool getIdentifiersForName(
            const std::string &name, TypeIdentifierPair &typeIdentifiers
        ) SWIFT_NAME(getIdentifiersForName(name:identifiers:));

        NODISCARD bool createStruct(
            const std::string &name, StructCreateInfo &info
        ) SWIFT_NAME(createStruct(name:info:));
        NODISCARD bool addStructMember(
            StructCreateInfo &info,
            const TypeIdentifierPair &memberIdentifiers,
            const std::string &name, uint32_t id, bool isOptional, bool isKey
        ) SWIFT_NAME(addStructMember(info:identifiers:name:id:isOptional:isKey:));
        NODISCARD eprosima::fastdds::dds::ReturnCode_t finishStruct(
            const StructCreateInfo &info, const std::string &name, TypeIdentifierPair &identifiers
        ) SWIFT_NAME(finishStruct(info:name:identifiers:));

        NODISCARD bool createUnion(
            const std::string &name, const TypeIdentifierPair &descriminator, bool isDescriminatorKey, UnionCreateInfo &info
        ) SWIFT_NAME(createUnion(name:descriminator:isDescriminatorKey:info:));
        NODISCARD bool addUnionCase(
            UnionCreateInfo &info,
            const TypeIdentifierPair &memberIdentifiers,
            const std::string &name, uint32_t caseId
        ) SWIFT_NAME(addUnionCase(info:identifiers:name:id:));
        NODISCARD eprosima::fastdds::dds::ReturnCode_t finishUnion(
            const UnionCreateInfo &info, const std::string &name, TypeIdentifierPair &identifiers
        ) SWIFT_NAME(finishUnion(info:name:identifiers:));

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
