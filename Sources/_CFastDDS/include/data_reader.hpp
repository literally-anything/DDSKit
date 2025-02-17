/*
 * data_reader.hpp
 * include
 * 
 * Created by Hunter Baker on 2/05/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <swift/bridging>

#include "common.h"
#include "topic.hpp"
#include "subscriber.hpp"
#include "swift_helpers.hpp"

#include <fastdds/dds/core/status/StatusMask.hpp>
#include <fastdds/dds/subscriber/DataReader.hpp>
#include <fastdds/dds/subscriber/DataReaderListener.hpp>
#include <fastdds/dds/subscriber/qos/DataReaderQos.hpp>

namespace FastDDS {

    class DataReader final {
    public:
        using _DataReader = eprosima::fastdds::dds::DataReader;
        using DataReaderQos = eprosima::fastdds::dds::DataReaderQos;
        using StatusMask = eprosima::fastdds::dds::StatusMask;

        static INLINE DataReaderQos getDefaultQos(const Subscriber &subscriberWrapper) SWIFT_NAME(getDefaultQos(subscriber:)) {
            return subscriberWrapper.subscriber->get_default_datareader_qos();
        }

        INLINE DataReader(
            const Topic &topicWrapper, const Subscriber &subscriberWrapper,
            const std::string &profileName,
            _FastDDSHelpers::ReaderCallbacks * _Nonnull callbacks, const StatusMask &statusMask, bool &success
        ) SWIFT_NAME(init(topic:subscriber:profile:callbacks:statusMask:success:)) : topic(topicWrapper.topic), subscriber(subscriberWrapper.subscriber), listener(std::make_unique<Listener>(callbacks)) {
            dataReader = subscriber->create_datareader_with_profile(topic, profileName, listener.get(), statusMask);
            success = dataReader != nullptr;
            destroyed = !success;
        }

        INLINE DataReader(
            const Topic &topicWrapper, const Subscriber &subscriberWrapper,
            const DataReaderQos &qos,
            _FastDDSHelpers::ReaderCallbacks * _Nonnull callbacks, const StatusMask &statusMask, bool &success
        ) SWIFT_NAME(init(topic:subscriber:profile:callbacks:statusMask:success:)) : topic(topicWrapper.topic), subscriber(subscriberWrapper.subscriber), listener(std::make_unique<Listener>(callbacks)) {
            dataReader = subscriber->create_datareader(topic, qos, listener.get(), statusMask);
            success = dataReader != nullptr;
            destroyed = !success;
        }

        INLINE eprosima::fastdds::dds::ReturnCode_t destroy() {
            if (!destroyed) {
                auto ret = subscriber->delete_datareader(dataReader);
                if (ret != eprosima::fastdds::dds::RETCODE_OK) { return ret; }

                destroyed = true;
            }
            return eprosima::fastdds::dds::RETCODE_OK;
        }
        INLINE bool getDestroyed() const SWIFT_COMPUTED_PROPERTY {
            return destroyed;
        }

        INLINE std::string getTopic() const SWIFT_COMPUTED_PROPERTY {
            return topic->get_name();
        }

        INLINE std::string getTypeName() const SWIFT_COMPUTED_PROPERTY {
            return topic->get_type_name();
        }

        INLINE StatusMask getStatusMask() const SWIFT_COMPUTED_PROPERTY {
            return dataReader->get_status_mask();
        }
        INLINE void setStatusMask(const StatusMask &mask) SWIFT_COMPUTED_PROPERTY {
            dataReader->set_listener(listener.get(), mask);
        }

        INLINE DataReaderQos getQos() const SWIFT_COMPUTED_PROPERTY {
            return dataReader->get_qos();
        }
        INLINE void setQos(const DataReaderQos &qos) SWIFT_COMPUTED_PROPERTY {
            if (dataReader->set_qos(qos) != eprosima::fastdds::dds::RETCODE_OK) {
                EPROSIMA_LOG_WARNING(DataReader, "Failed to set QoS");
            }
        }

    private:
        class Listener final : public eprosima::fastdds::dds::DataReaderListener {
        public:
            _FastDDSHelpers::ReaderCallbacks * _Nonnull callbacks;

            INLINE explicit Listener(_FastDDSHelpers::ReaderCallbacks * _Nonnull callbacks) : callbacks(callbacks) {}
        };

        Topic::_Topic * _Nonnull topic;
        Subscriber::_Subscriber * _Nonnull subscriber;
        _DataReader * _Nonnull dataReader;
        std::unique_ptr<Listener> listener;

        bool destroyed = false;
    } SWIFT_NONCOPYABLE;

}
