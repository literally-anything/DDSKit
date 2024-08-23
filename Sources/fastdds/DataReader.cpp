#include "DataReader.hpp"

namespace fastdds {
    namespace _DataReader {
        bool compareQos(DataReaderQos rhs, DataReaderQos lhs) {
            return rhs == lhs;
        }

        Listener::Listener(DDSKitInternal::ReaderCallbacks *callbacks) : callbacks(callbacks) {}
        void Listener::on_data_available(DataReader *reader) {
            callbacks->dataAvailable();
        }
        void Listener::on_subscription_matched(DataReader *reader, const DDSSubscriptionMatchedStatus &status) {
            callbacks->subscriptionMatched(&status);
        }
        void Listener::on_requested_deadline_missed(DataReader *reader, const DDSDeadlineMissedStatus &status) {
            callbacks->requestedDeadlineMissed(&status);
        }
        void Listener::on_liveliness_changed(DataReader *reader, const DDSLivelinessChangedStatus &status) {
            callbacks->livelinessChanged(&status);
        }
        void Listener::on_sample_rejected(DataReader *reader, const DDSSampleRejectedStatus &status) {
            callbacks->sampleRejected(&status);
        }
        void Listener::on_requested_incompatible_qos(DataReader *reader, const DDSIncompatibleQosStatus &status) {
            callbacks->requestedIncompatibleQos(&status);
        }
        void Listener::on_sample_lost(DataReader *reader, const DDSSampleLostStatus &status) {
            callbacks->sampleLost(&status);
        }

        Listener *createListener(DDSKitInternal::ReaderCallbacks *callbacks) {
            return new Listener(callbacks);
        }
        void destroyListener(Listener *listener) {
            listener->~Listener();
        }

        DataReaderQos getDefaultQos(_Subscriber::Subscriber *subscriber) {
            return subscriber->get_default_datareader_qos();
        }

        DataReader *create(_Subscriber::Subscriber *subscriber, const std::string &profile, _Topic::Topic *topic) {
            return subscriber->create_datareader_with_profile(topic, profile);
        }
        DataReader *create(_Subscriber::Subscriber *subscriber, const DataReaderQos &qos, _Topic::Topic *topic) {
            return subscriber->create_datareader(topic, qos);
        }
        DDSReturnCode destroy(DataReader *reader) {
            return const_cast<_Subscriber::Subscriber *>(reader->get_subscriber())->delete_datareader(reader);
        }

        DataReaderQos getQos(DataReader *reader) {
            return reader->get_qos();
        }
        DDSReturnCode setQos(DataReader *reader, const DataReaderQos qos) {
            return reader->set_qos(qos);
        }
        DDSReturnCode setListener(DataReader *reader, Listener *listener, const _StatusMask &mask) {
            return reader->set_listener(listener, mask);
        }

        uint64_t getUnreadCount(DataReader *reader) {
            return reader->get_unread_count();
        }
        DDSReturnCode takeNextSample(DataReader *reader, void *data, epfastdds::SampleInfo &info) {
            return reader->take_next_sample(data, &info);
        }
        // DDSReturnCode take(DataReader *reader, epfastddsDataSeq &data, epfastddsSampleInfoSeq &infos) {
        //     return reader->take(data, infos);
        // }
        // DDSReturnCode returnLoan(DataReader *reader, epfastddsDataSeq &data, epfastddsSampleInfoSeq &infos) {
        //     return reader->return_loan(data, infos);
        // }
    }
}
