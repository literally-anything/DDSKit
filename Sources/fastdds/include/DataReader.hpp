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

namespace fastdds {
    typedef epfastdds::SubscriptionMatchedStatus DDSSubscriptionMatchedStatus;
    typedef epfastdds::DeadlineMissedStatus DDSDeadlineMissedStatus;
    typedef epfastdds::LivelinessChangedStatus DDSLivelinessChangedStatus;
    typedef epfastdds::SampleRejectedStatus DDSSampleRejectedStatus;
    typedef epfastdds::IncompatibleQosStatus DDSIncompatibleQosStatus;
    typedef epfastdds::SampleLostStatus DDSSampleLostStatus;

    typedef epfastdds::DataReaderListener _DataReaderListener;

    namespace _DataReader {
        typedef epfastdds::DataReader DataReader;
        typedef epfastdds::DataReaderQos DataReaderQos;

        bool compareQos(DataReaderQos rhs, DataReaderQos lhs);

        class Listener : public _DataReaderListener {
        private:
            DDSKitInternal::ReaderCallbacks *callbacks;

        public:
            explicit Listener(DDSKitInternal::ReaderCallbacks *callbacks);

            inline void on_data_available(DataReader *reader) override;
            inline void on_subscription_matched(DataReader *reader, const DDSSubscriptionMatchedStatus &status) override;
            inline void on_requested_deadline_missed(DataReader *reader, const DDSDeadlineMissedStatus &status) override;
            inline void on_liveliness_changed(DataReader *reader, const DDSLivelinessChangedStatus &status) override;
            inline void on_sample_rejected(DataReader *reader, const DDSSampleRejectedStatus &status) override;
            inline void on_requested_incompatible_qos(DataReader *reader, const DDSIncompatibleQosStatus &status) override;
            inline void on_sample_lost(DataReader *reader, const DDSSampleLostStatus &status) override;
        };

        Listener *createListener(DDSKitInternal::ReaderCallbacks *callbacks);
        void destroyListener(Listener *listener);

        DataReaderQos getDefaultQos(_Subscriber::Subscriber *subscriber);

        DataReader *create(_Subscriber::Subscriber *subscriber, const std::string &profile, _Topic::Topic *topic);
        DataReader *create(_Subscriber::Subscriber *subscriber, const DataReaderQos &qos, _Topic::Topic *topic);
        DDSReturnCode destroy(DataReader *reader);

        DataReaderQos getQos(DataReader *reader);
        DDSReturnCode setQos(DataReader *reader, const DataReaderQos qos);
        DDSReturnCode setListener(DataReader *reader, Listener *listener, const _StatusMask &mask);

        uint64_t getUnreadCount(DataReader *reader);
        DDSReturnCode takeNextSample(DataReader *reader, void *data, epfastdds::SampleInfo &info);
        // DDSReturnCode take(DataReader *reader, epfastdds::LoanableSequence<Foo, std::false_type> &data, epfastdds::SampleInfoSeq &infos);
        // DDSReturnCode returnLoan(DataReader *reader, epfastdds::DataSeq &data, epfastdds::SampleInfoSeq &infos);
    }
}
