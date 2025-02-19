/*
 * logging.cpp
 * src
 * 
 * Created by Hunter Baker on 2/12/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#include "logging.hpp"

#include "swift_helpers.hpp"

#include <fastdds/dds/log/Log.hpp>

using namespace eprosima::fastdds::dds;

class SwiftLogConsumer final : public LogConsumer {
public:
    SwiftLogConsumer() : base(_FastDDSHelpers::LogConsumerBase::init()), LogConsumer() {}
    ~SwiftLogConsumer() override {}

    void Consume(const Log::Entry &entry) override {
        switch (entry.kind) {
            case Log::Kind::Info:
                base.info(
                    entry.message,
                    entry.context.category,
                    entry.context.filename,
                    entry.context.function,
                    entry.context.line
                );
                break;
            case Log::Kind::Warning:
                base.warning(
                    entry.message,
                    entry.context.category,
                    entry.context.filename,
                    entry.context.function,
                    entry.context.line
                );
                break;
            case Log::Kind::Error:
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

namespace FastDDS {

    void initLogging() {
        Log::ClearConsumers();

        Log::RegisterConsumer(std::make_unique<SwiftLogConsumer>());

        // Use the lowest verbosity level so that all messages are passed through and log levels can be handled by swift-log
        Log::SetVerbosity(Log::Kind::Info);
    }

}
