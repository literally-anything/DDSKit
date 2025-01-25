/*
 * type_representation.hpp
 * include
 * 
 * Created by Hunter Baker on 1/24/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <swift/bridging>

#include "common.h"

#include <fastdds/dds/core/ReturnCode.hpp>
#include <fastcdr/xcdr/external.hpp>
#include <fastcdr/xcdr/optional.hpp>
#include <fastdds/dds/xtypes/common.hpp>
#include <fastdds/dds/xtypes/type_representation/ITypeObjectRegistry.hpp>
#include <fastdds/dds/xtypes/type_representation/TypeObject.hpp>
#include <fastdds/dds/domain/DomainParticipantFactory.hpp>
#include <fastdds/dds/xtypes/type_representation/TypeObjectUtils.hpp>
#include <fastdds/dds/xtypes/type_representation/detail/dds_xtypes_typeobject.hpp>

namespace XTypes {
    namespace fastddsxtypes = eprosima::fastdds::dds::xtypes;

    class CreateInfo final {
    public:
        INLINE CreateInfo() : struct_flags(), header(), member_seq(), type_ann_builtin(), ann_custom(), tmp_ann_custom() {}

        fastddsxtypes::StructTypeFlag struct_flags;
        fastddsxtypes::CompleteStructHeader header;
        fastddsxtypes::CompleteStructMemberSeq member_seq;
        eprosima::fastcdr::optional<fastddsxtypes::AppliedBuiltinTypeAnnotations> type_ann_builtin;
        eprosima::fastcdr::optional<fastddsxtypes::AppliedAnnotationSeq> ann_custom;
        fastddsxtypes::AppliedAnnotationSeq tmp_ann_custom;
    };

    INLINE fastddsxtypes::TypeIdentifierPair initIdentifierPair() {
        return fastddsxtypes::TypeIdentifierPair();
    }

    INLINE bool getIdentifiers(
        const std::string &name, fastddsxtypes::TypeIdentifierPair &typeIdentifiers
    ) SWIFT_NAME(getIdentifiers(name:identifiers:)) {
        auto ret = eprosima::fastdds::dds::DomainParticipantFactory::get_instance()->type_object_registry().get_type_identifiers(
            name,
            typeIdentifiers
        );
        return ret == eprosima::fastdds::dds::RETCODE_OK;
    }

    INLINE fastddsxtypes::CompleteStructMemberSeq createStruct(
        CreateInfo &info, const std::string &name
    ) SWIFT_NAME(createStruct(info:name:)) {
        info.struct_flags = fastddsxtypes::TypeObjectUtils::build_struct_type_flag(
            eprosima::fastdds::dds::xtypes::ExtensibilityKind::FINAL,
            false, false
        );
        fastddsxtypes::QualifiedTypeName type_name = name;
        eprosima::fastcdr::optional<fastddsxtypes::AppliedVerbatimAnnotation> verbatim;
        if (!info.tmp_ann_custom.empty()) {
            info.ann_custom = info.tmp_ann_custom;
        }

        fastddsxtypes::CompleteTypeDetail detail = fastddsxtypes::TypeObjectUtils::build_complete_type_detail(
            info.type_ann_builtin,
            info.ann_custom,
            name
        );
        info.header = fastddsxtypes::TypeObjectUtils::build_complete_struct_header(fastddsxtypes::TypeIdentifier(), detail);
        return fastddsxtypes::CompleteStructMemberSeq();
    }

    INLINE void finishAndRegisterStruct(
        const CreateInfo &info, const fastddsxtypes::CompleteStructMemberSeq &members, fastddsxtypes::TypeIdentifierPair &identifiers
    ) SWIFT_NAME(createStruct(info:members:identifiers:)) {
        auto struct_type = fastddsxtypes::TypeObjectUtils::build_complete_struct_type(
            info.struct_flags,
            info.header,
            members
        );
        if (
            eprosima::fastdds::dds::RETCODE_BAD_PARAMETER == fastddsxtypes::TypeObjectUtils::build_and_register_struct_type_object(
                struct_type, info.header.detail().type_name().to_string(), identifiers
            )
        ) {
            EPROSIMA_LOG_ERROR(XTYPES_TYPE_REPRESENTATION,
                    "HelloWorld already registered in TypeObjectRegistry for a different type.");
        }
    }

    INLINE void addStructMember(
        CreateInfo &info, fastddsxtypes::CompleteStructMemberSeq &members,
        const fastddsxtypes::TypeIdentifierPair &memberIdentifiers, const std::string &name, uint32_t id, bool isOptional, bool isKey
    ) SWIFT_NAME(addStructMember(info:members:identifiers:name:id:isOptional:isKey:)) {
        fastddsxtypes::StructMemberFlag member_flags_index = fastddsxtypes::TypeObjectUtils::build_struct_member_flag(
            eprosima::fastdds::dds::xtypes::TryConstructFailAction::DISCARD,
            isOptional, false, isKey, false
        );
        bool common_ec {false};
        fastddsxtypes::CommonStructMember common_index {
            fastddsxtypes::TypeObjectUtils::build_common_struct_member(
                id,
                member_flags_index,
                fastddsxtypes::TypeObjectUtils::retrieve_complete_type_identifier(memberIdentifiers, common_ec)
            )
        };
        if (!common_ec)
        {
            EPROSIMA_LOG_ERROR(XTYPES_TYPE_REPRESENTATION, "Structure index member TypeIdentifier inconsistent.");
            return;
        }
        eprosima::fastcdr::optional<fastddsxtypes::AppliedBuiltinMemberAnnotations> member_ann_builtin;
        info.ann_custom.reset();
        fastddsxtypes::CompleteMemberDetail detail_index = fastddsxtypes::TypeObjectUtils::build_complete_member_detail(
            name, member_ann_builtin, info.ann_custom
        );
        fastddsxtypes::CompleteStructMember member_index = fastddsxtypes::TypeObjectUtils::build_complete_struct_member(
            common_index, detail_index
        );
        fastddsxtypes::TypeObjectUtils::add_complete_struct_member(members, member_index);
    }
}
