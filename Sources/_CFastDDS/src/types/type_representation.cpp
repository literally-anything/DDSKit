/*
 * type_representation.cpp
 * types
 * 
 * Created by Hunter Baker on 3/18/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#include "types/type_representation.hpp"

#include <cstdint>
#include <fastcdr/cdr/fixed_size_string.hpp>
#include <fastdds/dds/core/detail/DDSReturnCode.hpp>
#include <fastdds/dds/log/Log.hpp>
#include <fastdds/dds/xtypes/type_representation/TypeObjectUtils.hpp>
#include <fastdds/dds/xtypes/type_representation/detail/dds_xtypes_typeobject.hpp>

/// Check if there is an identical type already registered under the same name, but only in debug mode, because this check happens before building in release mode
#if defined(DEBUG) && DEBUG == 1
#define debugCheckForIdenticalRegistered _debugCheckForIdenticalRegistered
#else
#define debugCheckForIdenticalRegistered(...)
#endif

namespace FastDDS {

    namespace Types {
        using fastddsxtypes::TypeObjectUtils;

        bool getIdentifiersForName(
            const std::string &name, TypeIdentifierPair &typeIdentifiers
        ) {
            auto ret = eprosima::fastdds::dds::DomainParticipantFactory::get_instance()->type_object_registry().get_type_identifiers(
                name,
                typeIdentifiers.pair
            );
            return ret == eprosima::fastdds::dds::RETCODE_OK;
        }

#if defined(DEBUG) && DEBUG == 1
        void _debugCheckForIdenticalRegistered(const CompleteStructType &completeType, TypeIdentifierPair &identifiers, bool &identicalRegistered) {
            std::string name = completeType.header().detail().type_name().to_string();

            // Check if the type is already registered and is identical
            TypeIdentifierPair foundIdentifiers;
            if (getIdentifiersForName(name, foundIdentifiers)) {
                eprosima::fastdds::dds::xtypes::TypeObject foundType;
                bool gotCompleteIdentifier = false;
                auto ret = eprosima::fastdds::dds::DomainParticipantFactory::get_instance()->type_object_registry().get_type_object(
                    TypeObjectUtils::retrieve_complete_type_identifier(foundIdentifiers.pair, gotCompleteIdentifier), foundType
                );
                if (!gotCompleteIdentifier) {
                    EPROSIMA_LOG_WARNING(Types.debugCheckForIdenticalRegistered, "Failed to get complete type identifier for: " << name);
                }

                if (ret == eprosima::fastdds::dds::RETCODE_OK) {
                    try {
                        if (foundType.complete().struct_type() == completeType) {
                            identicalRegistered = true;
                            EPROSIMA_LOG_INFO(Types.debugCheckForIdenticalRegistered, "Type already registered, but identical: " << name);
                            identifiers.pair = foundIdentifiers.pair;
                            return;
                        }
                    } catch (const eprosima::fastcdr::exception::BadParamException &e) {}
                }
            }
            identicalRegistered = false;
        }
#endif

        bool createStruct(
            const std::string &name, CreateInfo &info
        ) {
            info.struct_flags = TypeObjectUtils::build_struct_type_flag(
                fastddsxtypes::ExtensibilityKind::FINAL,
                false, false
            );
            fastddsxtypes::QualifiedTypeName type_name = name;
            if (!info.tmp_ann_custom.empty()) {
                info.ann_custom = info.tmp_ann_custom;
            }

            fastddsxtypes::CompleteTypeDetail detail = TypeObjectUtils::build_complete_type_detail(
                info.type_ann_builtin,
                info.ann_custom,
                name
            );
            CATCH_FOR_SWIFT(
                eprosima::fastdds::dds::xtypes::InvalidArgumentError,
                {
                    info.header = TypeObjectUtils::build_complete_struct_header(TypeIdentifier(), detail);
                }
            );
            return true;
        }
        bool addStructMember(
            CreateInfo &info,
            const TypeIdentifierPair &memberIdentifiers,
            const std::string &name, uint32_t id, bool isOptional, bool isKey
        ) {
            fastddsxtypes::StructMemberFlag member_flags_index = TypeObjectUtils::build_struct_member_flag(
                fastddsxtypes::TryConstructFailAction::DISCARD,
                isOptional, false, isKey, false
            );
            
            bool common_ec {false};
            fastddsxtypes::CommonStructMember common_index = {
                TypeObjectUtils::build_common_struct_member(
                    id,
                    member_flags_index,
                    TypeObjectUtils::retrieve_complete_type_identifier(memberIdentifiers.pair, common_ec)
                )
            };
            if (!common_ec) { return false; }

            optional<fastddsxtypes::AppliedBuiltinMemberAnnotations> member_ann_builtin;
            info.ann_custom.reset();
            fastddsxtypes::CompleteStructMember member_index;
            fastddsxtypes::CompleteMemberDetail detail_index = TypeObjectUtils::build_complete_member_detail(
                name, member_ann_builtin, info.ann_custom
            );
            member_index = TypeObjectUtils::build_complete_struct_member(
                common_index, detail_index
            );

            TypeObjectUtils::add_complete_struct_member(info.member_seq, member_index);
            return true;
        }

        eprosima::fastdds::dds::ReturnCode_t finishStruct(const CreateInfo &info, const std::string &name, TypeIdentifierPair &identifiers) {
            CompleteStructType completeStructType;
            CATCH_FOR_SWIFT_CUSTOM(
                fastddsxtypes::InvalidArgumentError,
                eprosima::fastdds::dds::RETCODE_ERROR,
                {
                    completeStructType = TypeObjectUtils::build_complete_struct_type(
                        info.struct_flags,
                        info.header,
                        info.member_seq
                    );
                }
            );

            bool identicalRegistered = false;
            debugCheckForIdenticalRegistered(completeStructType, identifiers, identicalRegistered);
            if (identicalRegistered) { return eprosima::fastdds::dds::RETCODE_OK; }

            // Try to register the type
            auto ret = TypeObjectUtils::build_and_register_struct_type_object(
                completeStructType, name, identifiers.pair
            );

            if (ret == eprosima::fastdds::dds::RETCODE_BAD_PARAMETER && !identicalRegistered) {
                EPROSIMA_LOG_ERROR(Types.finishStruct, "Type already registered as a different type: " << name);
            }

            return ret;
        }

        bool createString(
            const std::string &name, bool isWide, TypeIdentifierPair &identifiers
        ) {
            fastddsxtypes::SBound bound = 0;
            fastddsxtypes::StringSTypeDefn typeDef = TypeObjectUtils::build_string_s_type_defn(bound);
            auto ret = TypeObjectUtils::build_and_register_s_string_type_identifier(
                typeDef, name, identifiers.pair, isWide
            );
            return ret == eprosima::fastdds::dds::RETCODE_OK;
        }

        bool createArray(
            const std::string &name, std::vector<uint8_t> shape, const TypeIdentifierPair &elementIdentifiers, TypeIdentifierPair &identifiers
        ) {
            bool gotCompleteElementIdentifier = false;
            auto elementIdentifier = std::make_shared<TypeIdentifier>(
                TypeObjectUtils::retrieve_complete_type_identifier(elementIdentifiers.pair, gotCompleteElementIdentifier)
            );
            if (!gotCompleteElementIdentifier) {
                EPROSIMA_LOG_ERROR(Types.createArray, "Failed to get complete type identifier for element type of array: " << name);
                return false;
            }

            fastddsxtypes::EquivalenceKind elementTypeKind = fastddsxtypes::EK_COMPLETE;
            if (elementIdentifiers.pair.type_identifier2()._d() == fastddsxtypes::TK_NONE) {
                elementTypeKind = fastddsxtypes::EK_BOTH;
            }
            fastddsxtypes::CollectionElementFlag elementFlags = 0;
            fastddsxtypes::PlainCollectionHeader header = TypeObjectUtils::build_plain_collection_header(elementTypeKind, elementFlags);

            fastddsxtypes::SBoundSeq bounds;
            for (uint8_t &dim : shape) {
                TypeObjectUtils::add_array_dimension(bounds, dim);
            }

            fastddsxtypes::PlainArraySElemDefn arrayDefinition = TypeObjectUtils::build_plain_array_s_elem_defn(
                header, bounds,
                elementIdentifier
            );
            auto ret = TypeObjectUtils::build_and_register_s_array_type_identifier(
                arrayDefinition, name, identifiers.pair
            );
            return ret == eprosima::fastdds::dds::RETCODE_OK;
        }

        bool createArray(
            const std::string &name, std::vector<uint32_t> shape, const TypeIdentifierPair &elementIdentifiers, TypeIdentifierPair &identifiers
        ) {
            bool gotCompleteElementIdentifier = false;
            auto elementIdentifier = std::make_shared<TypeIdentifier>(
                TypeObjectUtils::retrieve_complete_type_identifier(elementIdentifiers.pair, gotCompleteElementIdentifier)
            );
            if (!gotCompleteElementIdentifier) {
                EPROSIMA_LOG_ERROR(Types.createArray, "Failed to get complete type identifier for element type of array: " << name);
                return false;
            }

            fastddsxtypes::EquivalenceKind elementTypeKind = fastddsxtypes::EK_COMPLETE;
            if (elementIdentifiers.pair.type_identifier2()._d() == fastddsxtypes::TK_NONE) {
                elementTypeKind = fastddsxtypes::EK_BOTH;
            }
            fastddsxtypes::CollectionElementFlag elementFlags = 0;
            fastddsxtypes::PlainCollectionHeader header = TypeObjectUtils::build_plain_collection_header(elementTypeKind, elementFlags);

            fastddsxtypes::LBoundSeq bounds;
            for (uint32_t &dim : shape) {
                TypeObjectUtils::add_array_dimension(bounds, dim);
            }

            fastddsxtypes::PlainArrayLElemDefn arrayDefinition = TypeObjectUtils::build_plain_array_l_elem_defn(
                header, bounds,
                elementIdentifier
            );
            auto ret = TypeObjectUtils::build_and_register_l_array_type_identifier(
                arrayDefinition, name, identifiers.pair
            );
            return ret == eprosima::fastdds::dds::RETCODE_OK;
        }

        bool createSequence(
            const std::string &name, const TypeIdentifierPair &elementIdentifiers, TypeIdentifierPair &identifiers
        ) {
            bool gotCompleteElementIdentifier = false;
            auto elementIdentifier = std::make_shared<TypeIdentifier>(
                TypeObjectUtils::retrieve_complete_type_identifier(elementIdentifiers.pair, gotCompleteElementIdentifier)
            );
            if (!gotCompleteElementIdentifier) {
                EPROSIMA_LOG_ERROR(Types.createSequence, "Failed to get complete type identifier for element type of sequence: " << name);
                return false;
            }

            fastddsxtypes::EquivalenceKind elementTypeKind = fastddsxtypes::EK_COMPLETE;
            if (elementIdentifiers.pair.type_identifier2()._d() == fastddsxtypes::TK_NONE) {
                elementTypeKind = fastddsxtypes::EK_BOTH;
            }
            fastddsxtypes::CollectionElementFlag elementFlags = 0;
            fastddsxtypes::PlainCollectionHeader header = TypeObjectUtils::build_plain_collection_header(elementTypeKind, elementFlags);

            fastddsxtypes::SBound bound = 0;
            fastddsxtypes::PlainSequenceSElemDefn sequenceDefinition = TypeObjectUtils::build_plain_sequence_s_elem_defn(
                header, bound,
                elementIdentifier
            );
            auto ret = TypeObjectUtils::build_and_register_s_sequence_type_identifier(
                sequenceDefinition, name, identifiers.pair
            );
            return ret == eprosima::fastdds::dds::RETCODE_OK;
        }

        // bool createMap(
        //     const std::string &name, const TypeIdentifierPair &keyIdentifiers, const TypeIdentifierPair &valueIdentifiers, TypeIdentifierPair &identifiers
        // ) {
        //     bool gotCompleteKeyIdentifier = false;
        //     TypeIdentifier keyIdentifier = TypeIdentifier(
        //         TypeObjectUtils::retrieve_complete_type_identifier(keyIdentifiers.pair, gotCompleteKeyIdentifier)
        //     );
        //     if (!gotCompleteKeyIdentifier) {
        //         EPROSIMA_LOG_ERROR(Types.createSequence, "Failed to get complete type identifier for key type of map: " << name);
        //         return false;
        //     }

        //     bool gotCompleteValueIdentifier = false;
        //     TypeIdentifier valueIdentifier = TypeIdentifier(
        //         TypeObjectUtils::retrieve_complete_type_identifier(valueIdentifiers.pair, gotCompleteValueIdentifier)
        //     );
        //     if (!gotCompleteValueIdentifier) {
        //         EPROSIMA_LOG_ERROR(Types.createSequence, "Failed to get complete type identifier for value type of map: " << name);
        //         return false;
        //     }
        // }

    }

}
