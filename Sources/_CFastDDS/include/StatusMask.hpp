/*
 * StatusMask.hpp
 * include
 * 
 * Created by Hunter Baker on 1/21/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <cstdint>

#include "common.h"

#include <fastdds/dds/core/status/StatusMask.hpp>

INLINE uint32_t StatusMask_rawValue(const eprosima::fastdds::dds::StatusMask &mask) {
    return mask.to_ulong();
}

INLINE void StatusMask_add(eprosima::fastdds::dds::StatusMask &mask, const eprosima::fastdds::dds::StatusMask &&addedMask) {
    mask << addedMask;
}

INLINE void StatusMask_remove(eprosima::fastdds::dds::StatusMask &mask, const eprosima::fastdds::dds::StatusMask &&removedMask) {
    mask >> removedMask;
}
