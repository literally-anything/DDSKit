#pragma once

#include <string>

#include "types.hpp"
#include "Topic.hpp"
#include "Publisher.hpp"
#include "../../../.compatibility-headers/DDSKitInternal-Swift.h"

#include <fastdds/dds/publisher/DataWriter.hpp>
#include <fastdds/dds/publisher/DataWriterListener.hpp>
#include <fastdds/dds/publisher/qos/DataWriterQos.hpp>
#include <fastdds/rtps/common/WriteParams.hpp>

typedef fastdds::DataWriterListener _DataWriterListener;

namespace _DataWriter {
    typedef fastdds::DataWriter DataWriter;
    typedef fastdds::DataWriterQos DataWriterQos;
    typedef fastrtps::WriteParams WriteParams;

    bool compareQos(DataWriterQos rhs, DataWriterQos lhs);

    class Listener : public _DataWriterListener {
    private:
        DDSKitInternal::WriterCallbacks *callbacks;

    public:
        explicit Listener(DDSKitInternal::WriterCallbacks *callbacks);

        void on_publication_matched(DataWriter *writer, const fastdds::PublicationMatchedStatus &status) override;
        void on_offered_deadline_missed(DataWriter *writer, const fastdds::OfferedDeadlineMissedStatus &status) override;
        void on_offered_incompatible_qos(DataWriter *writer, const fastdds::OfferedIncompatibleQosStatus &status) override;
        void on_liveliness_lost(DataWriter *writer, const fastdds::LivelinessLostStatus &status) override;
        void on_unacknowledged_sample_removed(DataWriter *writer, const fastdds::InstanceHandle_t &instance) override;
    };

    Listener *createListener(DDSKitInternal::WriterCallbacks *callbacks);
    void destroyListener(Listener *listener);

    DataWriterQos getDefaultQos(_Publisher::Publisher *publisher);

    DataWriter *create(_Publisher::Publisher *publisher, const std::string &profile, _Topic::Topic *topic);
    DataWriter *create(_Publisher::Publisher *publisher, const DataWriterQos &qos, _Topic::Topic *topic);
    _ReturnCode destroy(DataWriter *writer);

    DataWriterQos getQos(DataWriter *writer);
    _ReturnCode setQos(DataWriter *writer, const DataWriterQos qos);
    _ReturnCode setListener(DataWriter *writer, Listener *listener, const _StatusMask &mask);

    _ReturnCode write(DataWriter *writer, const void *const data, const WriteParams params);
    void *getLoanPool(DataWriter *writer);
    _ReturnCode discardLoanedSample(DataWriter *writer, void *sample);
}
