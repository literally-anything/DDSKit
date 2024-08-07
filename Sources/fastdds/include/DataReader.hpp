#pragma once

#include "types.hpp"
#include <cstdint>
#include <string>
#include "Topic.hpp"
#include "Subscriber.hpp"
#include <fastdds/dds/subscriber/DataReader.hpp>
#include <fastdds/dds/subscriber/DataReaderListener.hpp>
#include <fastdds/dds/subscriber/qos/DataReaderQos.hpp>
#include <fastdds/dds/subscriber/SampleInfo.hpp>
#include <fastdds/dds/core/status/StatusMask.hpp>

typedef fastdds::DataReaderListener _DataReaderListener;

namespace _DataReader {
    typedef fastdds::DataReader DataReader;
    typedef fastdds::DataReaderQos DataReaderQos;

    class Listener : public _DataReaderListener {
    public:
        void *context = nullptr;

        void(*onDataAvailable)(void *context, DataReader *reader) = nullptr;
        void(*onSubscriptionMatched)(void *context, DataReader *reader, const fastdds::SubscriptionMatchedStatus *status) = nullptr;
        void(*onRequestedDeadlineMissed)(void *context, DataReader *reader, const fastdds::RequestedDeadlineMissedStatus *status) = nullptr;
        void(*onLivelinessChanged)(void *context, DataReader *reader, const fastdds::LivelinessChangedStatus *status) = nullptr;
        void(*onSampleRejected)(void *context, DataReader *reader, const fastdds::SampleRejectedStatus *status) = nullptr;
        void(*onRequestedIncompatibleQos)(void *context, DataReader *reader, const fastdds::RequestedIncompatibleQosStatus *status) = nullptr;
        void(*onSampleLost)(void *context, DataReader *reader, const fastdds::SampleLostStatus *status) = nullptr;

        void on_data_available(DataReader *reader) override;
        void on_subscription_matched(DataReader *reader, const fastdds::SubscriptionMatchedStatus &status) override;
        void on_requested_deadline_missed(DataReader *reader, const fastdds::RequestedDeadlineMissedStatus &status) override;
        void on_liveliness_changed(DataReader *reader, const fastdds::LivelinessChangedStatus &status) override;
        void on_sample_rejected(DataReader *reader, const fastdds::SampleRejectedStatus &status) override;
        void on_requested_incompatible_qos(DataReader *reader, const fastdds::RequestedIncompatibleQosStatus &status) override;
        void on_sample_lost(DataReader *reader, const fastdds::SampleLostStatus &status) override;
    };

    std::shared_ptr<Listener> createListener();
    Listener *getListenerPtr(std::shared_ptr<Listener> listener);
    void setListenerContext(std::shared_ptr<Listener> listener, void *context);
    void setListenerDataAvailableCallback(std::shared_ptr<Listener> listener,
                                          void(*onDataAvailable)(void *context, DataReader *reader));
    void setListenerSubscriptionMatchedCallback(std::shared_ptr<Listener> listener,
                                                void(*onSubscriptionMatched)(void *context, DataReader *reader, const fastdds::SubscriptionMatchedStatus *status));
    void setListenerRequestedDeadlineMissedCallback(std::shared_ptr<Listener> listener,
                                                    void(*onRequestedDeadlineMissed)(void *context, DataReader *reader, const fastdds::RequestedDeadlineMissedStatus *status));
    void setListenerLivelinessChangedCallback(std::shared_ptr<Listener> listener,
                                              void(*onLivelinessChanged)(void *context, DataReader *reader, const fastdds::LivelinessChangedStatus *status));
    void setListenerSampleRejectedCallback(std::shared_ptr<Listener> listener,
                                           void(*onSampleRejected)(void *context, DataReader *reader, const fastdds::SampleRejectedStatus *status));
    void setListenerRequestedIncompatibleQosCallback(std::shared_ptr<Listener> listener,
                                                     void(*onRequestedIncompatibleQos)(void *context, DataReader *reader, const fastdds::RequestedIncompatibleQosStatus *status));
    void setListenerSampleLostCallback(std::shared_ptr<Listener> listener,
                                       void(*onSampleLost)(void *context, DataReader *reader, const fastdds::SampleLostStatus *status));

    DataReaderQos getDefaultQos(_Subscriber::Subscriber *subscriber);

    DataReader *create(_Subscriber::Subscriber *subscriber, const std::string &profile, _Topic::Topic *topic,
                       Listener *listener = nullptr, const _StatusMask &mask = _StatusMask::all());
    DataReader *create(_Subscriber::Subscriber *subscriber, const DataReaderQos &qos, _Topic::Topic *topic,
                       Listener *listener = nullptr, const _StatusMask &mask = _StatusMask::all());
    _ReturnCode destroy(DataReader *reader);

    uint64_t getUnreadCount(DataReader *reader);
    _ReturnCode takeNextSample(DataReader *reader, void *data, fastdds::SampleInfo &info);
    // _ReturnCode take(DataReader *reader, eprosima::fastdds::dds::LoanableSequence<Foo, std::false_type> &data, fastdds::SampleInfoSeq &infos);
    // _ReturnCode returnLoan(DataReader *reader, fastdds::DataSeq &data, fastdds::SampleInfoSeq &infos);
}
