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

namespace FastDDS {

    using eprosima::fastdds::dds::StatusMask;

    namespace StatusMaskHelpers {
        INLINE uint32_t getRawValue(const StatusMask &mask) {
            return mask.to_ulong();
        }

        INLINE void add(StatusMask &mask, const StatusMask &addedMask) {
            mask << addedMask;
        }

        INLINE void remove(StatusMask &mask, const StatusMask &removedMask) {
            mask >> removedMask;
        }
    }

}
