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
#include <fastdds/dds/xtypes/type_representation/TypeObjectUtils.hpp>

namespace FastDDS {

    namespace Types {

        namespace fastddsxtypes = eprosima::fastdds::dds::xtypes;

        using eprosima::fastcdr::optional;
        using fastddsxtypes::TypeObjectUtils;
        using fastddsxtypes::TypeIdentifier;

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

        NODISCARD INLINE bool getIdentifiersForName(
            const std::string &name, TypeIdentifierPair &typeIdentifiers
        ) SWIFT_NAME(getIdentifiersForName(name:identifiers:)) {
            auto ret = eprosima::fastdds::dds::DomainParticipantFactory::get_instance()->type_object_registry().get_type_identifiers(
                name,
                typeIdentifiers.pair
            );
            return ret == eprosima::fastdds::dds::RETCODE_OK;
        }

        NODISCARD INLINE bool createStruct(
            const std::string &name, CreateInfo &info
        ) SWIFT_NAME(createStruct(name:info:)) {
            info.struct_flags = TypeObjectUtils::build_struct_type_flag(
                fastddsxtypes::ExtensibilityKind::FINAL,
                false, false
            );
            fastddsxtypes::QualifiedTypeName type_name = name;
            if (!info.tmp_ann_custom.empty()) {
                info.ann_custom = info.tmp_ann_custom;
            }

            try {
                fastddsxtypes::CompleteTypeDetail detail = TypeObjectUtils::build_complete_type_detail(
                    info.type_ann_builtin,
                    info.ann_custom,
                    name
                );
                info.header = TypeObjectUtils::build_complete_struct_header(TypeIdentifier(), detail);
            } catch (...) { return false; }
            return true;
        }
        NODISCARD INLINE bool addStructMember(
            CreateInfo &info,
            const TypeIdentifierPair &memberIdentifiers,
            const std::string &name, uint32_t id, bool isOptional, bool isKey
        ) SWIFT_NAME(addStructMember(info:identifiers:name:id:isOptional:isKey:)) {
            fastddsxtypes::StructMemberFlag member_flags_index = TypeObjectUtils::build_struct_member_flag(
                fastddsxtypes::TryConstructFailAction::DISCARD,
                isOptional, false, isKey, false
            );
            bool common_ec {false};
            fastddsxtypes::CommonStructMember common_index;
            try {
                common_index = {
                    TypeObjectUtils::build_common_struct_member(
                        id,
                        member_flags_index,
                        TypeObjectUtils::retrieve_complete_type_identifier(memberIdentifiers.pair, common_ec)
                    )
                };
            } catch (...) { return false; }
            if (!common_ec) { return false; }

            optional<fastddsxtypes::AppliedBuiltinMemberAnnotations> member_ann_builtin;
            info.ann_custom.reset();
            fastddsxtypes::CompleteStructMember member_index;
            try {
                fastddsxtypes::CompleteMemberDetail detail_index = TypeObjectUtils::build_complete_member_detail(
                    name, member_ann_builtin, info.ann_custom
                );
                member_index = TypeObjectUtils::build_complete_struct_member(
                    common_index, detail_index
                );
            } catch (...) { return false; }

            TypeObjectUtils::add_complete_struct_member(info.member_seq, member_index);
            return true;
        }
        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t finishStruct(
            const CreateInfo &info,
            std::string &name, TypeIdentifierPair &identifiers
        ) SWIFT_NAME(finishStruct(info:name:identifiers:)) {
            eprosima::fastdds::dds::xtypes::CompleteStructType completeStructType;
            try {
                completeStructType = TypeObjectUtils::build_complete_struct_type(
                    info.struct_flags,
                    info.header,
                    info.member_seq
                );
            } catch (...) { return eprosima::fastdds::dds::RETCODE_ERROR; }

            name = completeStructType.header().detail().type_name().to_string();

            try {
                return TypeObjectUtils::build_and_register_struct_type_object(
                    completeStructType, name, identifiers.pair
                );
            } catch (...) { return eprosima::fastdds::dds::RETCODE_ERROR; }
        }

    }

}
