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
#include "sample_identity.hpp"

#include <fastdds/dds/log/Log.hpp>
#include <fastdds/dds/core/detail/DDSReturnCode.hpp>
#include <fastdds/dds/xtypes/dynamic_types/DynamicData.hpp>

using namespace eprosima::fastdds::dds;

namespace FastDDS {

    DataReader::Listener::Listener(const Callbacks &callbacks, bool loanable) : loanable(loanable) {
        subscriptionMatchedCallback = Block_copy(callbacks.subscriptionMatchedCallback);
        onDataCallback = Block_copy(callbacks.onDataCallback);
        onErrorCallback = Block_copy(callbacks.onErrorCallback);
    }

    DataReader::Listener::~Listener() {
        Block_release(subscriptionMatchedCallback);
        Block_release(onDataCallback);
        Block_release(onErrorCallback);
    }

    void DataReader::Listener::on_subscription_matched(_DataReader *writer, const SubscriptionMatchedStatus &info) {
        subscriptionMatchedCallback(info.current_count, info.current_count_change);
    }

    void DataReader::Listener::on_data_available(_DataReader *reader) {
        if (loanable) {
            LoaningSequence data;
            SampleInfoSeq infos;
            // Loan a sequence of messages
            ReturnCode_t ret = reader->take(data, infos);
            while (ret == RETCODE_OK) {
                // Iterate over each message
                for (LoanableCollection::size_type i = 0; i < infos.length(); ++i)
                {
                    // Check whether the DataSample contains data or is only used to communicate of a change in the instance
                    if (infos[i].valid_data)
                    {
                        SampleIdentity identity = infos[i].sample_identity;
                        SampleIdentity related = infos[i].related_sample_identity;
                        onDataCallback(data.get(i), &identity, &related);
                    }
                }

                // Return the loan so the dataWriter can reuse the memory
                reader->return_loan(data, infos);

                // Try to take another sequence
                ret = reader->take(data, infos);
            }

            if (ret != RETCODE_NO_DATA) {
                EPROSIMA_LOG_INFO(DataReader::Listener, "Error while taking data: " << ret);
                onErrorCallback(ret);
            }
        } else {
            void *data = reader->type().create_data();
            SampleInfo info;

            ReturnCode_t ret = reader->take_next_sample(data, &info);
            while (ret == RETCODE_OK) {
                SampleIdentity identity = info.sample_identity;
                SampleIdentity related = info.related_sample_identity;
                onDataCallback(data, &identity, &related);

                // Try to take another sequence
                ret = reader->take_next_sample(data, &info);
            }

            if (ret != RETCODE_NO_DATA) {
                EPROSIMA_LOG_INFO(DataReader::Listener, "Error while taking data: " << ret);
                onErrorCallback(ret);
            }

            reader->type().delete_data(data);
        }
    }

}
