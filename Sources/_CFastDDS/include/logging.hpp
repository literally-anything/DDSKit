/*
 * logging.hpp
 * include
 * 
 * Created by Hunter Baker on 1/23/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <memory>
#include <swift/bridging>

#include "common.h"
#include "swift_helpers.hpp"

#include <fastdds/dds/log/Log.hpp>

class SwiftLogConsumer final : public eprosima::fastdds::dds::LogConsumer {
public:
    INLINE SwiftLogConsumer() : base(_FastDDSHelpers::LogConsumerBase::init()), LogConsumer() {}
    INLINE ~SwiftLogConsumer() override {}

    INLINE void Consume(const eprosima::fastdds::dds::Log::Entry &entry) override {
        switch (entry.kind) {
            case eprosima::fastdds::dds::Log::Kind::Info:
                base.info(
                    entry.message,
                    entry.context.category,
                    entry.context.filename,
                    entry.context.function,
                    entry.context.line
                );
                break;
            case eprosima::fastdds::dds::Log::Kind::Warning:
                base.warning(
                    entry.message,
                    entry.context.category,
                    entry.context.filename,
                    entry.context.function,
                    entry.context.line
                );
                break;
            case eprosima::fastdds::dds::Log::Kind::Error:
                base.error(
                    entry.message,
                    entry.context.category,
                    entry.context.filename,
                    entry.context.function,
                    entry.context.line
                );
        }
    }

private:
    _FastDDSHelpers::LogConsumerBase base;
};

INLINE void FastDDS_initLogging() {
    static bool initialized = false;
    if (!initialized) {
        eprosima::fastdds::dds::Log::RegisterConsumer(std::make_unique<SwiftLogConsumer>());
    }
}
