#pragma once

#include "types.hpp"

#include <fastdds/dds/topic/TopicDataType.hpp>

namespace fastdds {
    class _DataTypeHelper : public epfastdds::TopicDataType {
    private:
        bool isBounded;
        eprosima::fastdds::MD5 md5_;
        unsigned char* key_buffer_;

    public:
        _DataTypeHelper(const std::string name, bool isBounded, uint32_t maxSize, uint32_t maxKeySize);
        ~_DataTypeHelper() override;

        inline bool is_bounded() const override;
        inline bool is_plain(epfastdds::DataRepresentationId_t data_representation) const override;
        // inline bool construct_sample(void* memory) const override;
        
        // _TypeSupport getTypeSupport() const;
    };
}
