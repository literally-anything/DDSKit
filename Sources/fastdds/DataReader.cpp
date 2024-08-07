#include "DataReader.hpp"

namespace _DataReader {
    void Listener::on_data_available(DataReader *reader) {
        if (onDataAvailable != nullptr) {
            onDataAvailable(context, reader);
        }
    }
    void Listener::on_subscription_matched(DataReader *reader, const fastdds::SubscriptionMatchedStatus &status) {
        if (onSubscriptionMatched != nullptr) {
            onSubscriptionMatched(context, reader, &status);
        }
    }
    void Listener::on_requested_deadline_missed(DataReader *reader, const fastdds::RequestedDeadlineMissedStatus &status) {
        if (onRequestedDeadlineMissed != nullptr) {
            onRequestedDeadlineMissed(context, reader, &status);
        }
    }
    void Listener::on_liveliness_changed(DataReader *reader, const fastdds::LivelinessChangedStatus &status) {
        if (onLivelinessChanged != nullptr) {
            onLivelinessChanged(context, reader, &status);
        }
    }
    void Listener::on_sample_rejected(DataReader *reader, const fastdds::SampleRejectedStatus &status) {
        if (onSampleRejected != nullptr) {
            onSampleRejected(context, reader, &status);
        }
    }
    void Listener::on_requested_incompatible_qos(DataReader *reader, const fastdds::RequestedIncompatibleQosStatus &status) {
        if (onRequestedIncompatibleQos != nullptr) {
            onRequestedIncompatibleQos(context, reader, &status);
        }
    }
    void Listener::on_sample_lost(DataReader *reader, const fastdds::SampleLostStatus &status) {
        if (onSampleLost != nullptr) {
            onSampleLost(context, reader, &status);
        }
    }

    std::shared_ptr<Listener> createListener() {
        return std::make_shared<Listener>();
    }
    Listener *getListenerPtr(std::shared_ptr<Listener> listener) {
        return listener.get();
    }
    void setListenerContext(std::shared_ptr<Listener> listener, void *context) {
        listener->context = context;
    }
    void setListenerDataAvailableCallback(std::shared_ptr<Listener> listener,
                                          void(*onDataAvailable)(void *context, DataReader *reader)) {
        listener->onDataAvailable = onDataAvailable;
    }
    void setListenerSubscriptionMatchedCallback(std::shared_ptr<Listener> listener,
                                                void(*onSubscriptionMatched)(void *context, DataReader *reader, const fastdds::SubscriptionMatchedStatus *status)) {
        listener->onSubscriptionMatched = onSubscriptionMatched;
    }
    void setListenerRequestedDeadlineMissedCallback(std::shared_ptr<Listener> listener,
                                                    void(*onRequestedDeadlineMissed)(void *context, DataReader *reader, const fastdds::RequestedDeadlineMissedStatus *status)) {
        listener->onRequestedDeadlineMissed = onRequestedDeadlineMissed;
    }
    void setListenerLivelinessChangedCallback(std::shared_ptr<Listener> listener,
                                              void(*onLivelinessChanged)(void *context, DataReader *reader, const fastdds::LivelinessChangedStatus *status)) {
        listener->onLivelinessChanged = onLivelinessChanged;
    }
    void setListenerSampleRejectedCallback(std::shared_ptr<Listener> listener,
                                           void(*onSampleRejected)(void *context, DataReader *reader, const fastdds::SampleRejectedStatus *status)) {
        listener->onSampleRejected = onSampleRejected;
    }
    void setListenerRequestedIncompatibleQosCallback(std::shared_ptr<Listener> listener,
                                                     void(*onRequestedIncompatibleQos)(void *context, DataReader *reader, const fastdds::RequestedIncompatibleQosStatus *status)) {
        listener->onRequestedIncompatibleQos = onRequestedIncompatibleQos;
    }
    void setListenerSampleLostCallback(std::shared_ptr<Listener> listener,
                                       void(*onSampleLost)(void *context, DataReader *reader, const fastdds::SampleLostStatus *status)) {
        listener->onSampleLost = onSampleLost;
    }

    DataReaderQos getDefaultQos(_Subscriber::Subscriber *subscriber) {
        return subscriber->get_default_datareader_qos();
    }

    DataReader *create(_Subscriber::Subscriber *subscriber, const std::string &profile, _Topic::Topic *topic,
                       Listener *listener, const _StatusMask &mask) {
        return subscriber->create_datareader_with_profile(topic, profile, listener, mask);
    }
    DataReader *create(_Subscriber::Subscriber *subscriber, const DataReaderQos &qos, _Topic::Topic *topic,
                       Listener *listener, const _StatusMask &mask) {
        return subscriber->create_datareader(topic, qos, listener, mask);
    }
    _ReturnCode destroy(DataReader *reader) {
        return const_cast<_Subscriber::Subscriber *>(reader->get_subscriber())->delete_datareader(reader);
    }

    uint64_t getUnreadCount(DataReader *reader) {
        return reader->get_unread_count();
    }
    _ReturnCode takeNextSample(DataReader *reader, void *data, fastdds::SampleInfo &info) {
        return reader->take_next_sample(data, &info);
    }
    // _ReturnCode take(DataReader *reader, fastdds::DataSeq &data, fastdds::SampleInfoSeq &infos) {
    //     return reader->take(data, infos);
    // }
    // _ReturnCode returnLoan(DataReader *reader, fastdds::DataSeq &data, fastdds::SampleInfoSeq &infos) {
    //     return reader->return_loan(data, infos);
    // }
}
