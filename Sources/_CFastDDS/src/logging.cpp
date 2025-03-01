/*
 * logging.cpp
 * src
 * 
 * Created by Hunter Baker on 2/12/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#include "logging.hpp"

#include <fastdds/dds/log/Log.hpp>

using namespace eprosima::fastdds::dds;

class SwiftLogConsumer final : public LogConsumer {
public:
    SwiftLogConsumer(FastDDS::LogCallback_t logCallback) : callback(logCallback), LogConsumer() {}
    ~SwiftLogConsumer() override {}

    void Consume(const Log::Entry &entry) override {
        switch (entry.kind) {
            case Log::Kind::Info:
                callback(
                    0, entry.message.c_str(), entry.context.category,
                    entry.context.filename, entry.context.function, entry.context.line
                );
                break;
            case Log::Kind::Warning:
                callback(
                    1, entry.message.c_str(), entry.context.category,
                    entry.context.filename, entry.context.function, entry.context.line
                );
                break;
            case Log::Kind::Error:
                callback(
                    2, entry.message.c_str(), entry.context.category,
                    entry.context.filename, entry.context.function, entry.context.line
                );
        }
    }

private:
    FastDDS::LogCallback_t callback;
};

namespace FastDDS {

    void initLogging(LogCallback_t logCallback) {
        Log::ClearConsumers();

        Log::RegisterConsumer(std::make_unique<SwiftLogConsumer>(logCallback));

        // Use the lowest verbosity level so that all messages are passed through and log levels can be handled by swift-log
        Log::SetVerbosity(Log::Kind::Info);
    }

}
