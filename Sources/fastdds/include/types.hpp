#pragma once

#include <vector>
#include <cstdint>
#include <fastdds/dds/core/Types.hpp>
#include <fastdds/dds/core/detail/DDSReturnCode.hpp>
#include <fastdds/dds/topic/TypeSupport.hpp>
#include <fastdds/dds/core/status/StatusMask.hpp>
#include <fastdds/dds/subscriber/SampleInfo.hpp>

using _Int8Array = std::vector<int8_t>;
using _UInt8Array = std::vector<uint8_t>;
using _Int16Array = std::vector<int16_t>;
using _UInt16Array = std::vector<uint16_t>;
using _Int32Array = std::vector<int32_t>;
using _UInt32Array = std::vector<uint32_t>;
using _Int64Array = std::vector<int64_t>;
using _UInt64Array = std::vector<uint64_t>;
using _FloatArray = std::vector<float>;
using _DoubleArray = std::vector<double>;
using _Float80Array = std::vector<long double>;
using _BoolArray = std::vector<bool>;

namespace fastdds {
    namespace epfastdds = eprosima::fastdds::dds;
    namespace epfastrtps = eprosima::fastdds::rtps;

    typedef epfastdds::TypeSupport _TypeSupport;
    typedef epfastdds::StatusMask _StatusMask;
    typedef epfastdds::SampleInfo _SampleInfo;

    typedef epfastdds::ReturnCode_t DDSReturnCode;
    typedef epfastdds::DomainId_t DDSDomainId;
}
