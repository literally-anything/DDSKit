/*
 * cdr.hpp
 * include
 * 
 * Created by Hunter Baker on 1/22/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <cstdint>

#if __has_include(<swift/bridging>)
# include <swift/bridging>
#else
# include "utils/swift_bridging.h"
#endif

#include "common.h"

#include <fastdds/dds/topic/TopicDataType.hpp>
#include <fastdds/rtps/common/SerializedPayload.hpp>

namespace FastDDS {

    class GenericTopicType final : public eprosima::fastdds::dds::TopicDataType {
    public:
        using registerTypeCallback_t = void (^ SENDABLE _Nonnull)(eprosima::fastdds::dds::xtypes::TypeIdentifierPair &identifiers);
        using serializeCallback_t = bool (^ SENDABLE _Nonnull)(
            const void * _Nonnull const data,
            eprosima::fastdds::rtps::SerializedPayload_t &payload,
            eprosima::fastdds::dds::DataRepresentationId_t data_representation
        );
        using deserializeCallback_t = bool (^ SENDABLE _Nonnull)(
            eprosima::fastdds::rtps::SerializedPayload_t &payload,
            void * _Nonnull data
        );
        using calculateSizeCallback_t = uint32_t (^ SENDABLE _Nonnull)(
            const void * _Nonnull const data,
            eprosima::fastdds::dds::DataRepresentationId_t data_representation
        );
        // using computeKeyCallback_t = bool (^ SENDABLE _Nonnull)(
        //     const void* const data,
        //     eprosima::fastdds::rtps::InstanceHandle_t &ihandle,
        //     bool force_md5
        // );
        using createCallback_t = void * _Nonnull (^ SENDABLE _Nonnull)();
        using destroyCallback_t = void (^ SENDABLE _Nonnull)(void * _Nonnull data);
        using constructCallback_t = void (^ SENDABLE _Nonnull)(void * _Nonnull memory);

        GenericTopicType(
            const std::string &name,
            bool isBounded, bool isPlain, uint32_t maxSize,
            registerTypeCallback_t registerType,
            serializeCallback_t serialize, deserializeCallback_t deserialize,
            calculateSizeCallback_t calculateSize,
            createCallback_t create, destroyCallback_t destroy, constructCallback_t construct
        ) SWIFT_NAME(
            init(name:isBounded:isPlain:maxSize:registerType:serialize:deserialize:calculateSize:create:destroy:construct:)
        );
        GenericTopicType(const GenericTopicType &other);
        ~GenericTopicType() override;

        // static TypeSupportWrapper getTypeSupport(const GenericTopicType &type) {
        //     return TypeSupportWrapper(
        //         eprosima::fastdds::dds::TypeSupport(
        //             new GenericTopicType(type)
        //         )
        //     );
        // }

        bool serialize(
            const void * _Nonnull const data,
            eprosima::fastdds::rtps::SerializedPayload_t &payload,
            eprosima::fastdds::dds::DataRepresentationId_t data_representation
        ) override;
        bool deserialize(
            eprosima::fastdds::rtps::SerializedPayload_t &payload,
            void * _Nonnull data
        ) override;

        uint32_t calculate_serialized_size(
            const void * _Nonnull const data,
            eprosima::fastdds::dds::DataRepresentationId_t data_representation
        ) override;

        void * _Nonnull create_data() override;
        void delete_data(void * _Nonnull data) override;

        bool compute_key(
            eprosima::fastdds::rtps::SerializedPayload_t &payload,
            eprosima::fastdds::rtps::InstanceHandle_t &ihandle,
            bool force_md5 = false
        ) override;
        bool compute_key(
            const void * _Nonnull const data,
            eprosima::fastdds::rtps::InstanceHandle_t &ihandle,
            bool force_md5 = false
        ) override;

        INLINE bool is_bounded() const override {
            return isBounded;
        }
        INLINE bool is_plain(eprosima::fastdds::dds::DataRepresentationId_t data_representation) const override {
            return isPlain;
        }

        bool construct_sample(void * _Nonnull memory) const override;

        void register_type_object_representation() override;

    private:
        const bool isBounded;
        const bool isPlain;
        // const uint32_t maxKeySize = 0;
        const uint32_t maxSize;

        registerTypeCallback_t registerTypeCallback;
        serializeCallback_t serializeCallback;
        deserializeCallback_t deserializeCallback;
        calculateSizeCallback_t calculateSizeCallback;
        // computeKeyCallback_t computeKeyCallback;
        createCallback_t createCallback;
        destroyCallback_t destroyCallback;
        constructCallback_t constructCallback;

        // eprosima::fastdds::MD5 md5_;
        // unsigned char* key_buffer_;
    };

}
