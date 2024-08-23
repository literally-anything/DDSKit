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

namespace fastdds {
    typedef epfastdds::PublicationMatchedStatus DDSPublicationMatchedStatus;
    typedef epfastdds::OfferedDeadlineMissedStatus DDSOfferedDeadlineMissedStatus;
    typedef epfastdds::OfferedIncompatibleQosStatus DDSOfferedIncompatibleQosStatus;
    typedef epfastdds::LivelinessLostStatus DDSLivelinessLostStatus;
    typedef epfastdds::InstanceHandle_t DDSInstanceHandle_t;

    typedef epfastdds::DataWriterListener _DataWriterListener;

    namespace _DataWriter {
        typedef epfastdds::DataWriter DataWriter;
        typedef epfastdds::DataWriterQos DataWriterQos;
        typedef epfastrtps::WriteParams WriteParams;

        bool compareQos(DataWriterQos rhs, DataWriterQos lhs);

        class Listener : public _DataWriterListener {
        private:
            DDSKitInternal::WriterCallbacks *callbacks;

        public:
            explicit Listener(DDSKitInternal::WriterCallbacks *callbacks);

            void on_publication_matched(DataWriter *writer, const DDSPublicationMatchedStatus &status) override;
            void on_offered_deadline_missed(DataWriter *writer, const DDSOfferedDeadlineMissedStatus &status) override;
            void on_offered_incompatible_qos(DataWriter *writer, const DDSOfferedIncompatibleQosStatus &status) override;
            void on_liveliness_lost(DataWriter *writer, const DDSLivelinessLostStatus &status) override;
            void on_unacknowledged_sample_removed(DataWriter *writer, const DDSInstanceHandle_t &instance) override;
        };

        Listener *createListener(DDSKitInternal::WriterCallbacks *callbacks);
        void destroyListener(Listener *listener);

        DataWriterQos getDefaultQos(_Publisher::Publisher *publisher);

        DataWriter *create(_Publisher::Publisher *publisher, const std::string &profile, _Topic::Topic *topic);
        DataWriter *create(_Publisher::Publisher *publisher, const DataWriterQos &qos, _Topic::Topic *topic);
        DDSReturnCode destroy(DataWriter *writer);

        DataWriterQos getQos(DataWriter *writer);
        DDSReturnCode setQos(DataWriter *writer, const DataWriterQos qos);
        DDSReturnCode setListener(DataWriter *writer, Listener *listener, const _StatusMask &mask);

        DDSReturnCode write(DataWriter *writer, const void *const data, const WriteParams params);
        DDSReturnCode getLoanPool(DataWriter *writer, void *&sample);
        DDSReturnCode discardLoanedSample(DataWriter *writer, void *sample);
    }
}
