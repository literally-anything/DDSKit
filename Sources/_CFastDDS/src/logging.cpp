/*
 * logging.cpp
 * src
 * 
 * Created by Hunter Baker on 2/12/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#include "logging.hpp"

SwiftLogConsumer::SwiftLogConsumer() : base(_FastDDSHelpers::LogConsumerBase::init()), LogConsumer() {}
SwiftLogConsumer::~SwiftLogConsumer() {}

void SwiftLogConsumer::Consume(const eprosima::fastdds::dds::Log::Entry &entry) {
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

void fastDDS_initLogging() {
    using eprosima::fastdds::dds::Log;

    static bool initialized = false;
    if (!initialized) {
        Log::ClearConsumers();

        Log::RegisterConsumer(std::make_unique<SwiftLogConsumer>());
    }

    // Use the lowest verbosity level so that all messages are passed through and log levels can be handled by swift-log
    Log::SetVerbosity(Log::Kind::Info);
}
