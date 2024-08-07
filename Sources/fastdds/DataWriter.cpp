#include "DataWriter.hpp"

#include <stdexcept>
#include <string>

namespace _DataWriter {
    void Listener::on_publication_matched(DataWriter *writer, const fastdds::PublicationMatchedStatus &status) {
        if (onPublicationMatched != nullptr) {
            onPublicationMatched(context, writer, &status);
        }
    }
    void Listener::on_offered_deadline_missed(DataWriter *writer, const fastdds::OfferedDeadlineMissedStatus &status) {
        if (onOfferedDeadlineMissed != nullptr) {
            onOfferedDeadlineMissed(context, writer, &status);
        }
    }
    void Listener::on_offered_incompatible_qos(DataWriter *writer, const fastdds::OfferedIncompatibleQosStatus &status) {
        if (onOfferedIncompatibleQos != nullptr) {
            onOfferedIncompatibleQos(context, writer, &status);
        }
    }
    void Listener::on_liveliness_lost(DataWriter *writer, const fastdds::LivelinessLostStatus &status) {
        if (onLivelinessLost != nullptr) {
            onLivelinessLost(context, writer, &status);
        }
    }
    void Listener::on_unacknowledged_sample_removed(DataWriter *writer, const fastdds::InstanceHandle_t &instance) {
        if (onUnacknowledgedSampleEemoved != nullptr) {
            onUnacknowledgedSampleEemoved(context, writer, &instance);
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
    void setListenerPublicationMatchedCallback(std::shared_ptr<Listener> listener,
                                               void(*onPublicationMatched)(void *context, DataWriter *writer, const fastdds::PublicationMatchedStatus *status)) {
        listener->onPublicationMatched = onPublicationMatched;
    }
    void setListenerOfferedDeadlineMissedCallback(std::shared_ptr<Listener> listener,
                                                  void(*onOfferedDeadlineMissed)(void *context, DataWriter *writer, const fastdds::OfferedDeadlineMissedStatus *status)) {
        listener->onOfferedDeadlineMissed = onOfferedDeadlineMissed;
    }
    void setListenerOfferedIncompatibleQosCallback(std::shared_ptr<Listener> listener,
                                                   void(*onOfferedIncompatibleQos)(void *context, DataWriter *writer, const fastdds::OfferedIncompatibleQosStatus *status)) {
        listener->onOfferedIncompatibleQos = onOfferedIncompatibleQos;
    }
    void setListenerLivelinessLostCallback(std::shared_ptr<Listener> listener,
                                           void(*onLivelinessLost)(void *context, DataWriter *writer, const fastdds::LivelinessLostStatus *status)) {
        listener->onLivelinessLost = onLivelinessLost;
    }
    void setListenerUnacknowledgedSampleEemovedCallback(std::shared_ptr<Listener> listener,
                                                        void(*onUnacknowledgedSampleEemoved)(void *context, DataWriter *writer, const fastdds::InstanceHandle_t *instance)) {
        listener->onUnacknowledgedSampleEemoved = onUnacknowledgedSampleEemoved;
    }

    DataWriterQos getDefaultQos(_Publisher::Publisher *publisher) {
        return publisher->get_default_datawriter_qos();
    }

    DataWriter *create(_Publisher::Publisher *publisher, const std::string &profile, _Topic::Topic *topic,
                       Listener *listener, const _StatusMask &mask) {
        return publisher->create_datawriter_with_profile(topic, profile, listener, mask);
    }
    DataWriter *create(_Publisher::Publisher *publisher, const DataWriterQos &qos, _Topic::Topic *topic,
                       Listener *listener, const _StatusMask &mask) {
        return publisher->create_datawriter(topic, qos, listener, mask);
    }
    _ReturnCode destroy(DataWriter *writer) {
        return const_cast<_Publisher::Publisher *>(writer->get_publisher())->delete_datawriter(writer);
    }

    _ReturnCode write(DataWriter *writer, const void *const data, const WriteParams params) {
        return writer->write(data, const_cast<fastrtps::WriteParams &>(params));
    }
    void *getLoanPool(DataWriter *writer) {
        void *sample = nullptr;
        _ReturnCode ret = writer->loan_sample(sample);
        if (!ret) {
            throw std::runtime_error("Failed to loan sample:" + std::to_string(ret));
        }
        return sample;
    }
    _ReturnCode discardLoanedSample(DataWriter *writer, void *sample) {
        return writer->discard_loan(sample);
    }
}
