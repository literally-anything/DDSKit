#include "old/DataTypeHelper.hpp"

namespace fastdds {
    _DataTypeHelper::_DataTypeHelper(const std::string name, bool isBounded, uint32_t maxSize, uint32_t maxKeySize) : isBounded(isBounded) {
        set_name(name);

        uint32_t type_size = maxSize;
        type_size += static_cast<uint32_t>(eprosima::fastcdr::Cdr::alignment(type_size, 4)); /* possible submessage alignment */
        max_serialized_type_size = type_size + 4; /*encapsulation*/

        is_compute_key_provided = false;
        uint32_t key_length = maxKeySize > 16 ? maxKeySize : 16;
        key_buffer_ = reinterpret_cast<unsigned char*>(malloc(key_length));
        memset(key_buffer_, 0, key_length);
    }
    _DataTypeHelper::~_DataTypeHelper() {
        if (key_buffer_ != nullptr)
        {
            free(key_buffer_);
        }
    }

    bool _DataTypeHelper::is_bounded() const {
        return isBounded;
    }
    bool _DataTypeHelper::is_plain(epfastdds::DataRepresentationId_t data_representation) const {
        static_cast<void>(data_representation);
        return false;
    }
}
