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
        createCallback_t create, destroyCallback_t destroy, constructCallback_t construct,
        serializeCallback_t serialize, deserializeCallback_t deserialize,
        calculateSizeCallback_t calculateSize
    ) : isBounded(isBounded), isPlain(isPlain), maxSize(maxSize), TopicDataType() {
        max_serialized_type_size = maxSize + 4 + static_cast<uint32_t>(
            eprosima::fastcdr::Cdr::alignment(maxSize, 4)
        ); /* possible submessage alignment */

        set_name(name);
        is_compute_key_provided = false;

        // uint32_t key_length = maxKeySize > 16 ? maxKeySize : 16;
        // key_buffer_ = reinterpret_cast<unsigned char*>(malloc(key_length));
        // memset(key_buffer_, 0, key_length);

        registerTypeCallback = Block_copy(registerType);
        createCallback = Block_copy(create);
        destroyCallback = Block_copy(destroy);
        constructCallback = Block_copy(construct);

        serializeCallback = Block_copy(serialize);
        deserializeCallback = Block_copy(deserialize);
        calculateSizeCallback = Block_copy(calculateSize);
        // computeKeyCallback = Block_copy(computeKey);
    }
    GenericTopicType::GenericTopicType(const GenericTopicType &other) : GenericTopicType(
        other.get_name(),
        other.isBounded, other.isPlain, other.maxSize,
        other.registerTypeCallback,
        other.createCallback, other.destroyCallback, other.constructCallback,
        other.serializeCallback, other.deserializeCallback,
        other.calculateSizeCallback
    ) {
        // ToDo: Copy the key buffer when i implement keys
    }
    GenericTopicType::~GenericTopicType() {
        Block_release(registerTypeCallback);
        Block_release(createCallback);
        Block_release(destroyCallback);
        Block_release(constructCallback);

        Block_release(serializeCallback);
        Block_release(deserializeCallback);
        Block_release(calculateSizeCallback);
        // Block_release(computeKeyCallback);

        // if (key_buffer_ != nullptr) {
        //     free(key_buffer_);
        // }
    }

    bool GenericTopicType::serialize(
        const void * const data,
        eprosima::fastdds::rtps::SerializedPayload_t &payload,
        eprosima::fastdds::dds::DataRepresentationId_t data_representation
    ) {
        using InstanceHandle_t = eprosima::fastdds::rtps::InstanceHandle_t;
        using DataRepresentationId_t = eprosima::fastdds::dds::DataRepresentationId_t;

        eprosima::fastcdr::FastBuffer fastbuffer(reinterpret_cast<char*>(payload.data), payload.max_size);
        // Object that serializes the data.
        CDR::CDRSerializer ser(
            fastbuffer, eprosima::fastcdr::Cdr::DEFAULT_ENDIAN,
            data_representation == DataRepresentationId_t::XCDR_DATA_REPRESENTATION ? CDR::CDRVersion::XCDRv1 : CDR::CDRVersion::XCDRv2
        );
        payload.encapsulation = ser.cdr.endianness() == eprosima::fastcdr::Cdr::BIG_ENDIANNESS ? CDR_BE : CDR_LE;
        ser.cdr.set_encoding_flag(
            data_representation == DataRepresentationId_t::XCDR_DATA_REPRESENTATION ?
            eprosima::fastcdr::EncodingAlgorithmFlag::PLAIN_CDR :
            eprosima::fastcdr::EncodingAlgorithmFlag::DELIMIT_CDR2
        );

        ser.cdr.serialize_encapsulation();

        bool success = serializeCallback(data, ser);
        payload.length = static_cast<uint32_t>(ser.cdr.get_serialized_data_length());
        
        return success;
    }
    bool GenericTopicType::deserialize(
        eprosima::fastdds::rtps::SerializedPayload_t &payload,
        void *data
    ) {
        eprosima::fastcdr::FastBuffer fastbuffer(reinterpret_cast<char*>(payload.data), payload.length);

        // Object that deserializes the data.
        CDR::CDRDeserializer deser(fastbuffer, eprosima::fastcdr::Cdr::DEFAULT_ENDIAN, CDR::CDRVersion::XCDRv2);

        // Deserialize encapsulation.
        deser.cdr.read_encapsulation();
        payload.encapsulation = deser.cdr.endianness() == eprosima::fastcdr::Cdr::BIG_ENDIANNESS ? CDR_BE : CDR_LE;

        return deserializeCallback(data, deser);
    }

    uint32_t GenericTopicType::calculate_serialized_size(
        const void * const data,
        eprosima::fastdds::dds::DataRepresentationId_t data_representation
    ) {
        return calculateSizeCallback(data, data_representation != eprosima::fastdds::dds::DataRepresentationId::XCDR_DATA_REPRESENTATION);
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
        return constructCallback(memory);
    }

    void GenericTopicType::register_type_object_representation() {
        type_identifiers_ = registerTypeCallback().pair;
    }

}
