/*
 * logging.hpp
 * include
 * 
 * Created by Hunter Baker on 1/23/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <cstdint>

namespace FastDDS {

    using LogCallback_t = void (* _Nonnull)(
        uint8_t level, const char * _Nonnull message, const char * _Nullable category,
        const char * _Nullable file, const char * _Nullable function, int line
    );

    void initLogging(LogCallback_t logCallback);

}
