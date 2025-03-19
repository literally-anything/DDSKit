/*
 * setup.hpp
 * include
 * 
 * Created by Hunter Baker on 2/18/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <cstdint>

#if __has_include(<swift/bridging>)
# include <swift/bridging>
#else
# include "utils/swift_bridging.h"
#endif

#include "common.h"

namespace FastDDS {

    using LogCallback_t = void (* _Nonnull)(
        uint8_t level, const char * _Nonnull message, const char * _Nullable category,
        const char * _Nullable file, const char * _Nullable function, int line
    );

    NODISCARD int32_t setup(LogCallback_t logCallback) SWIFT_NAME(setup(logCallback:));

    void setIntraProcessDelivery(bool enabled) SWIFT_NAME(setIntraProcessDelivery(enabled:));

}
