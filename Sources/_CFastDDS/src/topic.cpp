/*
 * topic.cpp
 * src
 * 
 * Created by Hunter Baker on 2/17/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#include "topic.hpp"

#include <../lib/swift/Block/Block.h>

#include <fastdds/dds/core/status/BaseStatus.hpp>

using namespace eprosima::fastdds::dds;

namespace FastDDS {

    Topic::Listener::Listener(const Callbacks &callbacks) {
        inconsitentTopicCallback = Block_copy(callbacks.inconsitentTopicCallback);
    }

    Topic::Listener::~Listener() {
        Block_release(inconsitentTopicCallback);
    }

    void Topic::Listener::on_inconsistent_topic(_Topic *topic, InconsistentTopicStatus status) {
        inconsitentTopicCallback(); // This is temporary. This will pass more data and be more useful, but this callback isn't even supported in FastDDS yet.
    }

}
