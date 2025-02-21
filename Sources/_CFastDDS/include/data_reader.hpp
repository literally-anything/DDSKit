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

#include <fastdds/dds/subscriber/DataReader.hpp>
#include <fastdds/dds/subscriber/DataReaderListener.hpp>
#include <fastdds/dds/subscriber/qos/DataReaderQos.hpp>

namespace FastDDS {

    class DataReader final {
    public:
        using _DataReader = eprosima::fastdds::dds::DataReader;
        using DataReaderQos = eprosima::fastdds::dds::DataReaderQos;
        using StatusMask = eprosima::fastdds::dds::StatusMask;

        
        using onSubscriptionMatched_t = void (^ SENDABLE _Nonnull)(int32_t matchCount, int32_t countChange);
        using onData_t = void (^ SENDABLE _Nonnull)(const void * _Nonnull const data);
        using onError_t = void (^ SENDABLE _Nonnull)(const eprosima::fastdds::dds::ReturnCode_t error);
        struct Callbacks {
            onSubscriptionMatched_t subscriptionMatchedCallback;
            onData_t onDataCallback;
            onError_t onErrorCallback;
        };


        class Qos final {
        public:
            INLINE Qos(const Subscriber &subscriberWrapper) SWIFT_NAME(init(subscriber:)) {
                qos = subscriberWrapper.subscriber->get_default_datareader_qos();
            }

            INLINE void setDataSharingModeOn(const char * _Nonnull dir) SWIFT_NAME(setDataSharingMode(dir:)) {
                qos.data_sharing().on(dir);
            }
            INLINE void setDataSharingModeOff() {
                qos.data_sharing().off();
            }

            INLINE const DataReaderQos &get() const {
                return qos;
            }

        private:
            DataReaderQos qos;
        };


        INLINE DataReader(
            const Topic &topicWrapper, const Subscriber &subscriberWrapper,
            const Qos &qos,
            bool &success
        ) SWIFT_NAME(init(topic:subscriber:profile:success:)) : topic(topicWrapper.topic), subscriber(subscriberWrapper.subscriber) {
            dataReader = subscriber->create_datareader(topic, qos.get(), nullptr, StatusMask::none());
            success = dataReader != nullptr;
            destroyed = !success;
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t enable() {
            return dataReader->enable();
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t setCallbacks(const Callbacks &callbacks) {
            listener = std::make_unique<Listener>(callbacks);
            return dataReader->set_listener(listener.get(), StatusMask::subscription_matched() << StatusMask::data_available());
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t destroy() {
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


        INLINE int32_t getMatchedCount() const SWIFT_COMPUTED_PROPERTY {
            eprosima::fastdds::dds::SubscriptionMatchedStatus status;
            dataReader->get_subscription_matched_status(status);
            return status.current_count;
        }

    private:
        class Listener final : public eprosima::fastdds::dds::DataReaderListener {
        public:
            explicit Listener(const Callbacks &callbacks);
            ~Listener() override;

            // Non-copyable because it would deallocate the blocks
            Listener( const Listener& ) = delete;
            Listener& operator=( const Listener& ) = delete;

            void on_subscription_matched(_DataReader * _Nonnull reader, const eprosima::fastdds::dds::SubscriptionMatchedStatus &info) override;
            void on_data_available(_DataReader * _Nonnull reader) override;

        private:
            onSubscriptionMatched_t subscriptionMatchedCallback;
            onData_t onDataCallback;
            onError_t onErrorCallback;
        };

        Topic::_Topic * _Nonnull topic;
        Subscriber::_Subscriber * _Nonnull subscriber;
        _DataReader * _Nonnull dataReader;
        std::unique_ptr<Listener> listener;

        bool destroyed = false;
    } SWIFT_NONCOPYABLE;

}
