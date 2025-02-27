/*
 * cdr_size.hpp
 * include
 * 
 * Created by Hunter Baker on 1/25/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <cstddef>
#include <cstdint>
#include <fastcdr/Cdr.h>
#include <swift/bridging>

#include "common.h"

#include <fastcdr/CdrEncoding.hpp>
#include <fastcdr/xcdr/MemberId.hpp>
#include <fastcdr/CdrSizeCalculator.hpp>
#include <fastdds/dds/core/policy/QosPolicies.hpp>

namespace eprosima {
    namespace fastcdr {
        template<>
        INLINE size_t CdrSizeCalculator::calculate_member_serialized_size(const MemberId &id, const long long &data, size_t &current_alignment) {
            static_assert(sizeof(long long) == sizeof(int64_t), "DDSKit: long long is not the same size as int64_t");
            return calculate_member_serialized_size(id, static_cast<int64_t>(data), current_alignment);
        }

        template<>
        INLINE size_t CdrSizeCalculator::calculate_member_serialized_size(const MemberId &id, const unsigned long long &data, size_t &current_alignment) {
            static_assert(sizeof(unsigned long long) == sizeof(uint64_t), "DDSKit: unsigned long long is not the same size as uint64_t");
            return calculate_member_serialized_size(id, static_cast<uint64_t>(data), current_alignment);
        }
    }
}

namespace CDR {
    using eprosima::fastcdr::CdrSizeCalculator;
    using eprosima::fastdds::dds::DataRepresentationId_t;
    using eprosima::fastcdr::Cdr;

    // INLINE void *createCdr() {
    //     return new Cdr();
    // }
}
