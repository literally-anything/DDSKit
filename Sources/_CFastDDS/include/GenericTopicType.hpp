/*
 * cdr.hpp
 * include
 * 
 * Created by Hunter Baker on 1/22/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <cstdint>
#include <swift/bridging>
#include <../lib/swift/Block/Block.h>

#include "common.h"

#include <fastdds/rtps/common/SerializedPayload.hpp>
#include <fastdds/dds/topic/TopicDataType.hpp>
#include <fastdds/dds/topic/TypeSupport.hpp>
#include <fastdds/dds/domain/DomainParticipantFactory.hpp>
#include <fastdds/utils/md5.hpp>

#include <fastdds/dds/xtypes/type_representation/TypeObjectUtils.hpp>

class _TypeSupportWrapper final {
public:
    INLINE _TypeSupportWrapper(eprosima::fastdds::dds::TypeSupport &&typeSupport) : typeSupport(typeSupport) {}

    eprosima::fastdds::dds::TypeSupport typeSupport;
};

class GenericTopicType final : public eprosima::fastdds::dds::TopicDataType {
public:
    using registerTypeCallback_t = void (^ SENDABLE _Nonnull)(eprosima::fastdds::dds::xtypes::TypeIdentifierPair &identifiers);
    using serializeCallback_t = bool (^ SENDABLE _Nonnull)(
        const void* const data,
        eprosima::fastdds::rtps::SerializedPayload_t &payload,
        eprosima::fastdds::dds::DataRepresentationId_t data_representation
    );
    using deserializeCallback_t = bool (^ SENDABLE _Nonnull)(
        eprosima::fastdds::rtps::SerializedPayload_t &payload,
        void *data
    );
    using calculateSizeCallback_t = uint32_t (^ SENDABLE _Nonnull)(
        const void* const data,
        eprosima::fastdds::dds::DataRepresentationId_t data_representation
    );
    using computeKeyCallback_t = bool (^ SENDABLE _Nonnull)(
        eprosima::fastdds::rtps::SerializedPayload_t &payload,
        eprosima::fastdds::rtps::InstanceHandle_t &ihandle,
        bool force_md5
    );
    using computeKeyRawCallback_t = bool (^ SENDABLE _Nonnull)(
        const void* const data,
        eprosima::fastdds::rtps::InstanceHandle_t &ihandle,
        bool force_md5
    );
    using createCallback_t = void *(^ SENDABLE _Nonnull)();
    using destroyCallback_t = void (^ SENDABLE _Nonnull)(void *data);

    INLINE GenericTopicType(
        const std::string &name,
        bool computeKeyProvided, bool isBounded, bool isPlain, bool contructSample,
        uint32_t maxKeySize, uint32_t maxSize,
        registerTypeCallback_t registerType,
        serializeCallback_t serialize, deserializeCallback_t deserialize,
        calculateSizeCallback_t calculateSize, computeKeyCallback_t computeKey, computeKeyRawCallback_t computeKeyRaw,
        createCallback_t create, destroyCallback_t destroy
    ) SWIFT_NAME(
        init(name:hasComputeKey:isBounded:isPlain:contructSample:maxKeySize:maxSize:registerType:serialize:deserialize:calculateSize:computeKey:computeKeyRaw:create:destroy:)
    ) : isBounded(isBounded), isPlain(isPlain), contructSample(contructSample), maxKeySize(maxKeySize), maxSize(maxSize), TopicDataType() {
        set_name(name);
        is_compute_key_provided = computeKeyProvided;

        uint32_t key_length = maxKeySize > 16 ? maxKeySize : 16;
        key_buffer_ = reinterpret_cast<unsigned char*>(malloc(key_length));
        memset(key_buffer_, 0, key_length);

        registerTypeCallback = Block_copy(registerType);
        serializeCallback = Block_copy(serialize);
        deserializeCallback = Block_copy(deserialize);
        calculateSizeCallback = Block_copy(calculateSize);
        computeKeyCallback = Block_copy(computeKey);
        computeKeyRawCallback = Block_copy(computeKeyRaw);
        createCallback = Block_copy(create);
        destroyCallback = Block_copy(destroy);
    }

    INLINE GenericTopicType (const GenericTopicType &other) : GenericTopicType(
        other.get_name(),
        other.is_compute_key_provided,
        other.isBounded, other.isPlain, other.contructSample,
        other.maxKeySize, other.maxSize,
        other.registerTypeCallback,
        other.serializeCallback, other.deserializeCallback,
        other.calculateSizeCallback,
        other.computeKeyCallback, other.computeKeyRawCallback,
        other.createCallback, other.destroyCallback
    ) {}

    INLINE ~GenericTopicType() override {
        Block_release(registerTypeCallback);
        Block_release(serializeCallback);
        Block_release(deserializeCallback);
        Block_release(calculateSizeCallback);
        Block_release(computeKeyCallback);
        Block_release(computeKeyRawCallback);
        Block_release(createCallback);
        Block_release(destroyCallback);

        if (key_buffer_ != nullptr) {
            free(key_buffer_);
        }
    }

    INLINE bool serialize(
        const void* const data,
        eprosima::fastdds::rtps::SerializedPayload_t &payload,
        eprosima::fastdds::dds::DataRepresentationId_t data_representation
    ) override {
        return serializeCallback(data, payload, data_representation);
    }

    INLINE bool deserialize(
        eprosima::fastdds::rtps::SerializedPayload_t &payload,
        void *data
    ) override {
        return deserializeCallback(payload, data);
    }

    INLINE uint32_t calculate_serialized_size(
        const void* const data,
        eprosima::fastdds::dds::DataRepresentationId_t data_representation
    ) override {
        return calculate_serialized_size(data, data_representation);
    }

    INLINE bool compute_key(
        eprosima::fastdds::rtps::SerializedPayload_t &payload,
        eprosima::fastdds::rtps::InstanceHandle_t &ihandle,
        bool force_md5 = false
    ) override {
        return computeKeyCallback(payload, ihandle, force_md5);
    }

    INLINE bool compute_key(
        const void* const data,
        eprosima::fastdds::rtps::InstanceHandle_t &ihandle,
        bool force_md5 = false
    ) override {
        return computeKeyRawCallback(data, ihandle, force_md5);
    }

    INLINE void *create_data() override {
        return createCallback();
    }

    INLINE void delete_data(void *data) override {
        return destroyCallback(data);
    }

    INLINE void register_type_object_representation() override {
        registerTypeCallback(type_identifiers_);
    }

    INLINE bool is_bounded() const override {
        return isBounded;
    }

    INLINE bool is_plain(eprosima::fastdds::dds::DataRepresentationId_t data_representation) const override {
        static_cast<void>(data_representation);
        return isPlain;
    }

    INLINE bool construct_sample(void *memory) const override {
        static_cast<void>(memory);
        return contructSample;
    }

    INLINE static _TypeSupportWrapper getTypeSupport(const GenericTopicType &type) {
        return _TypeSupportWrapper(
            eprosima::fastdds::dds::TypeSupport(
                new GenericTopicType(type)
            )
        );
    }

private:
    const bool isBounded;
    const bool isPlain;
    const bool contructSample;
    const uint32_t maxKeySize;
    const uint32_t maxSize;

    registerTypeCallback_t registerTypeCallback;
    serializeCallback_t serializeCallback;
    deserializeCallback_t deserializeCallback;
    calculateSizeCallback_t calculateSizeCallback;
    computeKeyCallback_t computeKeyCallback;
    computeKeyRawCallback_t computeKeyRawCallback;
    createCallback_t createCallback;
    destroyCallback_t destroyCallback;

    eprosima::fastdds::MD5 md5_;
    unsigned char* key_buffer_;
};
