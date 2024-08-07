#include <vector>
#include <cstdint>
#include <fastdds/dds/core/Types.hpp>
#include <fastdds/dds/core/detail/DDSReturnCode.hpp>
#include <fastdds/dds/topic/TypeSupport.hpp>
#include <fastdds/dds/core/status/StatusMask.hpp>

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

namespace fastdds = eprosima::fastdds::dds;
namespace fastrtps = eprosima::fastdds::rtps;

typedef fastdds::ReturnCode_t _ReturnCode;
typedef fastdds::DomainId_t _DomainId;
typedef fastdds::TypeSupport _TypeSupport;
typedef fastdds::StatusMask _StatusMask;
