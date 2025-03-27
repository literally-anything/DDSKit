/*
 * cdr_size.hpp
 * include
 * 
 * Created by Hunter Baker on 1/25/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

// Ensure that the CDRSizeCalculator private members are accessible
#include "private_cdr.hpp"

#include <fastcdr/xcdr/MemberId.hpp>
#include <fastcdr/CdrSizeCalculator.hpp>
#include <fastdds/dds/core/policy/QosPolicies.hpp>

namespace FastDDS {

    namespace CDR {
        using CdrSizeCalculator = eprosima::fastcdr::CdrSizeCalculator;

        enum class SerializedMemberSizeForNextInt : uint32_t {
            NO_SERIALIZED_MEMBER_SIZE,
            SERIALIZED_MEMBER_SIZE,
            SERIALIZED_MEMBER_SIZE_4,
            SERIALIZED_MEMBER_SIZE_8
        };
    }

}
