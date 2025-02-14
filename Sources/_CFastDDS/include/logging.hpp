/*
 * logging.hpp
 * include
 * 
 * Created by Hunter Baker on 1/23/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <swift/bridging>

#include "swift_helpers.hpp"

#include <fastdds/dds/log/Log.hpp>

class SwiftLogConsumer final : public eprosima::fastdds::dds::LogConsumer {
public:
    SwiftLogConsumer();
    ~SwiftLogConsumer() override;

    void Consume(const eprosima::fastdds::dds::Log::Entry &entry) override;

private:
    _FastDDSHelpers::LogConsumerBase base;
};

void fastDDS_initLogging();
