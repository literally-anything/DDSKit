/*
 * guid.hpp
 * utils
 * 
 * Created by Hunter Baker on 2/26/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include "common.h"
#include <fastdds/rtps/common/Guid.hpp>
#include <fastdds/rtps/common/GuidPrefix_t.hpp>
#include <fastdds/rtps/common/InstanceHandle.hpp>

namespace FastDDS {

    using InstanceHandle = eprosima::fastdds::rtps::InstanceHandle_t;
    using GUID = eprosima::fastdds::rtps::GUID_t;
    using GUIDPrefix = eprosima::fastdds::rtps::GuidPrefix_t;
    using EntityID = eprosima::fastdds::rtps::EntityId_t;

    static const unsigned int GUIDPrefix_size = GUIDPrefix::size;
    static const unsigned int EntityID_size = EntityID::size;

    INLINE GUID guidFromInstanceHandle(const InstanceHandle &handle) {
        return eprosima::fastdds::rtps::iHandle2GUID(handle);
    }

}
