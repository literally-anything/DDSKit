/*
 * generic_topic_type.cpp
 * cdr
 * 
 * Created by Hunter Baker on 3/04/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#include "types/generic_topic_type.hpp"

#if __has_include(<Block.h>)
# include <Block.h>
#else
# include "../../src/utils/Block.h"
#endif

namespace FastDDS {

    GenericTopicType::GenericTopicType(
        const std::string &name,
        bool isBounded, bool isPlain, uint32_t maxSize,
        registerTypeCallback_t registerType,
        serializeCallback_t serialize, deserializeCallback_t deserialize,
        calculateSizeCallback_t calculateSize,
        createCallback_t create, destroyCallback_t destroy, constructCallback_t construct
    ) : isBounded(isBounded), isPlain(isPlain), maxSize(maxSize), TopicDataType() {

        set_name(name);
        is_compute_key_provided = false;

        // uint32_t key_length = maxKeySize > 16 ? maxKeySize : 16;
        // key_buffer_ = reinterpret_cast<unsigned char*>(malloc(key_length));
        // memset(key_buffer_, 0, key_length);

        registerTypeCallback = Block_copy(registerType);
        serializeCallback = Block_copy(serialize);
        deserializeCallback = Block_copy(deserialize);
        calculateSizeCallback = Block_copy(calculateSize);
        // computeKeyCallback = Block_copy(computeKey);
        createCallback = Block_copy(create);
        destroyCallback = Block_copy(destroy);
        constructCallback = Block_copy(construct);
    }
    GenericTopicType::GenericTopicType(const GenericTopicType &other) : GenericTopicType(
        other.get_name(),
        other.isBounded, other.isPlain, other.maxSize,
        other.registerTypeCallback,
        other.serializeCallback, other.deserializeCallback,
        other.calculateSizeCallback,
        other.createCallback, other.destroyCallback, other.constructCallback
    ) {
        // ToDo: Copy the key buffer when i implement keys
    }
    GenericTopicType::~GenericTopicType() {
        Block_release(registerTypeCallback);
        Block_release(serializeCallback);
        Block_release(deserializeCallback);
        Block_release(calculateSizeCallback);
        // Block_release(computeKeyCallback);
        Block_release(createCallback);
        Block_release(destroyCallback);
        Block_release(constructCallback);

        // if (key_buffer_ != nullptr) {
        //     free(key_buffer_);
        // }
    }

    bool GenericTopicType::serialize(
        const void * const data,
        eprosima::fastdds::rtps::SerializedPayload_t &payload,
        eprosima::fastdds::dds::DataRepresentationId_t data_representation
    ) {
        return serializeCallback(data, payload, data_representation);
    }
    bool GenericTopicType::deserialize(
        eprosima::fastdds::rtps::SerializedPayload_t &payload,
        void *data
    ) {
        return deserializeCallback(payload, data);
    }

    uint32_t GenericTopicType::calculate_serialized_size(
        const void * const data,
        eprosima::fastdds::dds::DataRepresentationId_t data_representation
    ) {
        return calculate_serialized_size(data, data_representation);
    }

    void *GenericTopicType::create_data() {
        return createCallback();
    }
    void GenericTopicType::delete_data(void *data) {
        return destroyCallback(data);
    }

    bool GenericTopicType::compute_key(
        eprosima::fastdds::rtps::SerializedPayload_t &payload,
        eprosima::fastdds::rtps::InstanceHandle_t &ihandle,
        bool force_md5
    ) {
        return false;
    }
    bool GenericTopicType::compute_key(
        const void* const data,
        eprosima::fastdds::rtps::InstanceHandle_t &ihandle,
        bool force_md5
    ) {
        return false;
    }

    bool GenericTopicType::construct_sample(void *memory) const {
        constructCallback(memory);
        return true;
    }

    void GenericTopicType::register_type_object_representation() {
        registerTypeCallback(type_identifiers_);
    }

}
