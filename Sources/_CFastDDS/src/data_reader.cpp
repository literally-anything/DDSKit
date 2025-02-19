/*
 * data_reader.cpp
 * src
 * 
 * Created by Hunter Baker on 2/18/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#include "data_reader.hpp"

#include <../lib/swift/Block/Block.h>

#include "loaning_sequence.hpp"

using namespace eprosima::fastdds::dds;

namespace FastDDS {

    DataReader::Listener::Listener(const Callbacks &callbacks) {
        subscriptionMatchedCallback = Block_copy(callbacks.subscriptionMatchedCallback);
        onDataCallback = Block_copy(callbacks.onDataCallback);
    }

    DataReader::Listener::~Listener() {
        Block_release(subscriptionMatchedCallback);
        Block_release(onDataCallback);
    }

    void DataReader::Listener::on_subscription_matched(_DataReader *writer, const SubscriptionMatchedStatus &info) {
        subscriptionMatchedCallback(info.current_count, info.current_count_change);
    }

    void DataReader::Listener::on_data_available(_DataReader *reader) {

        LoaningSequence data;
        SampleInfoSeq infos;
        // Loan a sequence of messages
        while (RETCODE_OK == reader->take(data, infos))
        {
            // Iterate over each message
            for (LoanableCollection::size_type i = 0; i < infos.length(); ++i)
            {
                // Check whether the DataSample contains data or is only used to communicate of a change in the instance
                if (infos[i].valid_data)
                {
                    onDataCallback(data.get(i));
                }
            }

            // Return the loan so the dataWriter can reuse the memory
            reader->return_loan(data, infos);
        }
    }

}
