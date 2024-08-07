#pragma once

#include "types.hpp"
#include <string>
#include "Topic.hpp"
#include "Publisher.hpp"
#include <fastdds/dds/publisher/DataWriter.hpp>
#include <fastdds/dds/publisher/DataWriterListener.hpp>
#include <fastdds/dds/publisher/qos/DataWriterQos.hpp>
#include <fastdds/rtps/common/WriteParams.hpp>

typedef fastdds::DataWriterListener _DataWriterListener;

namespace _DataWriter {
    typedef fastdds::DataWriter DataWriter;
    typedef fastdds::DataWriterQos DataWriterQos;
    typedef fastrtps::WriteParams WriteParams;

    class Listener : public _DataWriterListener {
    public:
        void *context = nullptr;

        void(*onPublicationMatched)(void *context, DataWriter *writer, const fastdds::PublicationMatchedStatus *status) = nullptr;
        void(*onOfferedDeadlineMissed)(void *context, DataWriter *writer, const fastdds::OfferedDeadlineMissedStatus *status) = nullptr;
        void(*onOfferedIncompatibleQos)(void *context, DataWriter *writer, const fastdds::OfferedIncompatibleQosStatus *status) = nullptr;
        void(*onLivelinessLost)(void *context, DataWriter *writer, const fastdds::LivelinessLostStatus *status) = nullptr;
        void(*onUnacknowledgedSampleEemoved)(void *context, DataWriter *writer, const fastdds::InstanceHandle_t *instance) = nullptr;

        void on_publication_matched(DataWriter *writer, const fastdds::PublicationMatchedStatus &status) override;
        void on_offered_deadline_missed(DataWriter *writer, const fastdds::OfferedDeadlineMissedStatus &status) override;
        void on_offered_incompatible_qos(DataWriter *writer, const fastdds::OfferedIncompatibleQosStatus &status) override;
        void on_liveliness_lost(DataWriter *writer, const fastdds::LivelinessLostStatus &status) override;
        void on_unacknowledged_sample_removed(DataWriter *writer, const fastdds::InstanceHandle_t &instance) override;
    };

    std::shared_ptr<Listener> createListener();
    Listener *getListenerPtr(std::shared_ptr<Listener> listener);
    void setListenerContext(std::shared_ptr<Listener> listener, void *context);
    void setListenerPublicationMatchedCallback(std::shared_ptr<Listener> listener,
                                               void(*onPublicationMatched)(void *context, DataWriter *writer, const fastdds::PublicationMatchedStatus *status));
    void setListenerOfferedDeadlineMissedCallback(std::shared_ptr<Listener> listener,
                                                  void(*onOfferedDeadlineMissed)(void *context, DataWriter *writer, const fastdds::OfferedDeadlineMissedStatus *status));
    void setListenerOfferedIncompatibleQosCallback(std::shared_ptr<Listener> listener,
                                                   void(*onOfferedIncompatibleQos)(void *context, DataWriter *writer, const fastdds::OfferedIncompatibleQosStatus *status));
    void setListenerLivelinessLostCallback(std::shared_ptr<Listener> listener,
                                           void(*onLivelinessLost)(void *context, DataWriter *writer, const fastdds::LivelinessLostStatus *status));
    void setListenerUnacknowledgedSampleEemovedCallback(std::shared_ptr<Listener> listener,
                                                        void(*onUnacknowledgedSampleEemoved)(void *context, DataWriter *writer, const fastdds::InstanceHandle_t *instance));

    DataWriterQos getDefaultQos(_Publisher::Publisher *publisher);

    DataWriter *create(_Publisher::Publisher *publisher, const std::string &profile, _Topic::Topic *topic,
                       Listener *listener = nullptr, const _StatusMask &mask = _StatusMask::all());
    DataWriter *create(_Publisher::Publisher *publisher, const DataWriterQos &qos, _Topic::Topic *topic,
                       Listener *listener = nullptr, const _StatusMask &mask = _StatusMask::all());
    _ReturnCode destroy(DataWriter *writer);

    _ReturnCode write(DataWriter *writer, const void *const data, const WriteParams params);
    void *getLoanPool(DataWriter *writer);
    _ReturnCode discardLoanedSample(DataWriter *writer, void *sample);
}
