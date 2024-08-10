#include "DataWriter.hpp"

#include <stdexcept>
#include <string>

namespace _DataWriter {
    bool compareQos(DataWriterQos rhs, DataWriterQos lhs) {
        return rhs == lhs;
    }

    Listener::Listener(DDSKitInternal::WriterCallbacks *callbacks) : callbacks(callbacks) {}
    void Listener::on_publication_matched(DataWriter *writer, const fastdds::PublicationMatchedStatus &status) {
        callbacks->publicationMatched(&status);
    }
    void Listener::on_offered_deadline_missed(DataWriter *writer, const fastdds::OfferedDeadlineMissedStatus &status) {
        callbacks->offeredDeadlineMissed(&status);
    }
    void Listener::on_offered_incompatible_qos(DataWriter *writer, const fastdds::OfferedIncompatibleQosStatus &status) {
        callbacks->offeredIncompatibleQos(&status);
    }
    void Listener::on_liveliness_lost(DataWriter *writer, const fastdds::LivelinessLostStatus &status) {
        callbacks->livelinessLost(&status);
    }
    void Listener::on_unacknowledged_sample_removed(DataWriter *writer, const fastdds::InstanceHandle_t &instance) {
        callbacks->unacknowledgedSampleRemoved(&instance);
    }

    Listener *createListener(DDSKitInternal::WriterCallbacks *callbacks) {
        return new Listener(callbacks);
    }
    void destroyListener(Listener *listener) {
        listener->~Listener();
    }

    DataWriterQos getDefaultQos(_Publisher::Publisher *publisher) {
        return publisher->get_default_datawriter_qos();
    }

    DataWriter *create(_Publisher::Publisher *publisher, const std::string &profile, _Topic::Topic *topic) {
        return publisher->create_datawriter_with_profile(topic, profile);
    }
    DataWriter *create(_Publisher::Publisher *publisher, const DataWriterQos &qos, _Topic::Topic *topic) {
        return publisher->create_datawriter(topic, qos);
    }
    _ReturnCode destroy(DataWriter *writer) {
        return const_cast<_Publisher::Publisher *>(writer->get_publisher())->delete_datawriter(writer);
    }

    DataWriterQos getQos(DataWriter *writer) {
        return writer->get_qos();
    }
    _ReturnCode setQos(DataWriter *writer, const DataWriterQos qos) {
        return writer->set_qos(qos);
    }
    _ReturnCode setListener(DataWriter *writer, Listener *listener, const _StatusMask &mask) {
        return writer->set_listener(listener, mask);
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
