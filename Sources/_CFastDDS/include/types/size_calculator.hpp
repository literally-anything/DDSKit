/*
 * cdr_size.hpp
 * include
 * 
 * Created by Hunter Baker on 1/25/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <fastcdr/xcdr/MemberId.hpp>
#include <fastcdr/CdrSizeCalculator.hpp>
#include <fastdds/dds/core/policy/QosPolicies.hpp>

namespace FastDDS {

    namespace CDR {
        using CdrSizeCalculator = eprosima::fastcdr::CdrSizeCalculator;
    }

}
