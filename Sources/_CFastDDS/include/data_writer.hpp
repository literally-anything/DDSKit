/*
 * data_writer.hpp
 * include
 * 
 * Created by Hunter Baker on 2/04/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <fastdds/dds/log/Log.hpp>
#include <swift/bridging>

#include "common.h"
#include "topic.hpp"
#include "publisher.hpp"
#include "swift_helpers.hpp"

#include <fastdds/rtps/writer/RTPSWriter.hpp>
#include <fastdds/dds/core/status/StatusMask.hpp>
#include <fastdds/dds/publisher/DataWriter.hpp>
#include <fastdds/dds/publisher/DataWriterListener.hpp>
#include <fastdds/dds/publisher/qos/DataWriterQos.hpp>

namespace FastDDS {

    class DataWriter final {
    public:
        using _DataWriter = eprosima::fastdds::dds::DataWriter;
        using DataWriterQos = eprosima::fastdds::dds::DataWriterQos;
        using StatusMask = eprosima::fastdds::dds::StatusMask;

        static INLINE DataWriterQos getDefaultQos(const Publisher &publisherWrapper) SWIFT_NAME(getDefaultQos(publisher:)) {
            return publisherWrapper.publisher->get_default_datawriter_qos();
        }

        INLINE DataWriter(
            const Topic &topicWrapper, const Publisher &publisherWrapper,
            const std::string &profileName,
            _FastDDSHelpers::WriterCallbacks * _Nonnull callbacks, const StatusMask &statusMask,
            bool &success
        ) SWIFT_NAME(init(topic:publisher:profile:callbacks:statusMask:success:)) : topic(topicWrapper.topic), publisher(publisherWrapper.publisher), listener(std::make_unique<Listener>(callbacks)) {
            dataWriter = publisher->create_datawriter_with_profile(topic, profileName, listener.get(), statusMask);
            success = dataWriter != nullptr;
        }

        INLINE DataWriter(
            const Topic &topicWrapper, const Publisher &publisherWrapper,
            const DataWriterQos &qos,
            _FastDDSHelpers::WriterCallbacks * _Nonnull callbacks, const StatusMask &statusMask,
            bool &success
        ) SWIFT_NAME(init(topic:publisher:profile:callbacks:statusMask:success:)) : topic(topicWrapper.topic), publisher(publisherWrapper.publisher), listener(std::make_unique<Listener>(callbacks)) {

            dataWriter = publisher->create_datawriter(topic, qos, listener.get(), statusMask);
            success = dataWriter != nullptr;
        }

        INLINE eprosima::fastdds::dds::ReturnCode_t destroy() {
            if (!destroyed) {
                auto ret = publisher->delete_datawriter(dataWriter);
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
            return dataWriter->get_status_mask();
        }
        INLINE void setStatusMask(const StatusMask &mask) SWIFT_COMPUTED_PROPERTY {
            dataWriter->set_listener(listener.get(), mask);
        }

        INLINE DataWriterQos getQos() const SWIFT_COMPUTED_PROPERTY {
            return dataWriter->get_qos();
        }
        INLINE void setQos(const DataWriterQos &qos) SWIFT_COMPUTED_PROPERTY {
            if (dataWriter->set_qos(qos) != eprosima::fastdds::dds::RETCODE_OK) {
                EPROSIMA_LOG_WARNING(DataWriter, "Failed to set QoS");
            }
        }

        INLINE eprosima::fastdds::dds::ReturnCode_t write(
            const void *const data, const eprosima::fastdds::rtps::WriteParams &params
        ) SWIFT_NAME(write(data:params:)) {
            return dataWriter->write(data, const_cast<eprosima::fastdds::rtps::WriteParams &>(params));
        }

    private:
        class Listener final : public eprosima::fastdds::dds::DataWriterListener {
        public:
            _FastDDSHelpers::WriterCallbacks *callbacks;

            INLINE explicit Listener(_FastDDSHelpers::WriterCallbacks *callbacks) : callbacks(callbacks) {}
        };

        Topic::_Topic *topic;
        Publisher::_Publisher *publisher;
        _DataWriter *dataWriter;
        std::unique_ptr<Listener> listener;

        bool destroyed = false;
    } SWIFT_NONCOPYABLE;

}
