/*
 * data_writer.cpp
 * src
 * 
 * Created by Hunter Baker on 2/17/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#include "data_writer.hpp"

#include <../lib/swift/Block/Block.h>

#include <fastdds/dds/core/status/PublicationMatchedStatus.hpp>

using namespace eprosima::fastdds::dds;

namespace FastDDS {

    DataWriter::Listener::Listener(const Callbacks &callbacks) {
        publicationMatchedCallback = Block_copy(callbacks.publicationMatchedCallback);
    }

    DataWriter::Listener::~Listener() {
        Block_release(publicationMatchedCallback);
    }

    void DataWriter::Listener::on_publication_matched(_DataWriter *writer, const PublicationMatchedStatus &info) {
        publicationMatchedCallback(info.current_count, info.current_count_change);
    }

}
