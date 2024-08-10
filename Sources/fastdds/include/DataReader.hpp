#pragma once

#include <cstdint>
#include <string>
#include <swift/bridging>

#include "types.hpp"
#include "Topic.hpp"
#include "Subscriber.hpp"
#include "../../../.compatibility-headers/DDSKitInternal-Swift.h"

#include <fastdds/dds/subscriber/DataReader.hpp>
#include <fastdds/dds/subscriber/DataReaderListener.hpp>
#include <fastdds/dds/subscriber/qos/DataReaderQos.hpp>
#include <fastdds/dds/subscriber/SampleInfo.hpp>
#include <fastdds/dds/core/status/StatusMask.hpp>

typedef fastdds::DataReaderListener _DataReaderListener;

namespace _DataReader {
    typedef fastdds::DataReader DataReader;
    typedef fastdds::DataReaderQos DataReaderQos;

    bool compareQos(DataReaderQos rhs, DataReaderQos lhs);

    class Listener : public _DataReaderListener {
    private:
        DDSKitInternal::ReaderCallbacks *callbacks;

    public:
        explicit Listener(DDSKitInternal::ReaderCallbacks *callbacks);

        inline void on_data_available(DataReader *reader) override;
        inline void on_subscription_matched(DataReader *reader, const fastdds::SubscriptionMatchedStatus &status) override;
        inline void on_requested_deadline_missed(DataReader *reader, const fastdds::RequestedDeadlineMissedStatus &status) override;
        inline void on_liveliness_changed(DataReader *reader, const fastdds::LivelinessChangedStatus &status) override;
        inline void on_sample_rejected(DataReader *reader, const fastdds::SampleRejectedStatus &status) override;
        inline void on_requested_incompatible_qos(DataReader *reader, const fastdds::RequestedIncompatibleQosStatus &status) override;
        inline void on_sample_lost(DataReader *reader, const fastdds::SampleLostStatus &status) override;
    };

    Listener *createListener(DDSKitInternal::ReaderCallbacks *callbacks);
    void destroyListener(Listener *listener);

    DataReaderQos getDefaultQos(_Subscriber::Subscriber *subscriber);

    DataReader *create(_Subscriber::Subscriber *subscriber, const std::string &profile, _Topic::Topic *topic);
    DataReader *create(_Subscriber::Subscriber *subscriber, const DataReaderQos &qos, _Topic::Topic *topic);
    _ReturnCode destroy(DataReader *reader);

    DataReaderQos getQos(DataReader *reader);
    _ReturnCode setQos(DataReader *reader, const DataReaderQos qos);
    _ReturnCode setListener(DataReader *reader, Listener *listener, const _StatusMask &mask);

    uint64_t getUnreadCount(DataReader *reader);
    _ReturnCode takeNextSample(DataReader *reader, void *data, fastdds::SampleInfo &info);
    // _ReturnCode take(DataReader *reader, eprosima::fastdds::dds::LoanableSequence<Foo, std::false_type> &data, fastdds::SampleInfoSeq &infos);
    // _ReturnCode returnLoan(DataReader *reader, fastdds::DataSeq &data, fastdds::SampleInfoSeq &infos);
}
