/*
 * data_reader.hpp
 * include
 * 
 * Created by Hunter Baker on 2/05/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#if __has_include(<swift/bridging>)
# include <swift/bridging>
#else
# include "utils/swift_bridging.h"
#endif

#include "common.h"
#include "topic.hpp"
#include "subscriber.hpp"
#include "utils/guid.hpp"

#include <fastdds/dds/subscriber/DataReader.hpp>
#include <fastdds/dds/subscriber/DataReaderListener.hpp>
#include <fastdds/dds/subscriber/qos/DataReaderQos.hpp>
#include <fastdds/dds/subscriber/SampleInfo.hpp>

namespace FastDDS {

    class DataReader final {
    public:
        using _DataReader = eprosima::fastdds::dds::DataReader;
        using DataReaderQos = eprosima::fastdds::dds::DataReaderQos;
        using StatusMask = eprosima::fastdds::dds::StatusMask;
        using SampleInfo = eprosima::fastdds::dds::SampleInfo;

        
        using onSubscriptionMatched_t = void (^ SENDABLE _Nonnull)(int32_t matchCount, int32_t countChange, GUID guid);
        using onData_t = void (^ SENDABLE _Nonnull)(
            const void * _Nonnull const data,
            const SampleInfo * _Nonnull const info
        );
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
            INLINE Qos(
                const Subscriber &subscriberWrapper, std::string profile, eprosima::fastdds::dds::ReturnCode_t &ret
            ) SWIFT_NAME(init(subscriber:profileName:ret:)) : Qos(subscriberWrapper) {
                ret = subscriberWrapper.subscriber->get_datareader_qos_from_profile(profile, qos);
            }

            INLINE void setDataSharingModeOn(const char * _Nonnull dir) SWIFT_NAME(setDataSharingMode(dir:)) {
                qos.data_sharing().on(dir);
            }
            INLINE void setDataSharingModeOff() {
                qos.data_sharing().off();
            }
            INLINE void setDataSharingModeAuto() {
                qos.data_sharing().automatic();
            }

            INLINE void setHistoryDepthEndless() {
                qos.history().kind = eprosima::fastdds::dds::KEEP_ALL_HISTORY_QOS;
            }
            INLINE void setHistoryDepth(uint32_t depth) {
                qos.history().kind = eprosima::fastdds::dds::KEEP_LAST_HISTORY_QOS;
                qos.history().depth = depth;
            }

            INLINE void setMaxBlockingTime(int32_t seconds, uint32_t nanoseconds) {
                qos.reliability().max_blocking_time = eprosima::fastdds::dds::Duration_t(seconds, nanoseconds);
            }
            INLINE void setReliability(bool reliable) {
                qos.reliability().kind = reliable ? eprosima::fastdds::dds::RELIABLE_RELIABILITY_QOS : eprosima::fastdds::dds::BEST_EFFORT_RELIABILITY_QOS;
            }

            INLINE const DataReaderQos &get() const {
                return qos;
            }

        private:
            DataReaderQos qos;
        };


        INLINE DataReader(
            const Topic &topicWrapper, const Subscriber &subscriberWrapper,
            const Qos &qos, bool loanable,
            bool &success
        ) SWIFT_NAME(init(topic:subscriber:profile:loanable:success:)) : topic(topicWrapper.topic), subscriber(subscriberWrapper.subscriber), loanable(loanable) {
            dataReader = subscriber->create_datareader(topic, qos.get(), nullptr, StatusMask::none());
            success = dataReader != nullptr;
            destroyed = !success;
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t enable() {
            return dataReader->enable();
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t setCallbacks(const Callbacks &callbacks) {
            listener = std::make_unique<Listener>(callbacks, loanable);
            return dataReader->set_listener(listener.get(), StatusMask::subscription_matched() << StatusMask::data_available());
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t destroy() {
            auto listenerRet = dataReader->set_listener(nullptr, StatusMask::none());
            if (!destroyed) {
                auto ret = subscriber->delete_datareader(dataReader);
                if (ret != eprosima::fastdds::dds::RETCODE_OK) { return ret; }

                destroyed = true;
            }
            listener = nullptr;
            return listenerRet;
        }
        INLINE bool getDestroyed() const SWIFT_COMPUTED_PROPERTY {
            return destroyed;
        }

        INLINE GUID getGuid() const SWIFT_COMPUTED_PROPERTY {
            return dataReader->guid();
        }

        INLINE int32_t getMatchedCount() const SWIFT_COMPUTED_PROPERTY {
            eprosima::fastdds::dds::SubscriptionMatchedStatus status;
            dataReader->get_subscription_matched_status(status);
            return status.current_count;
        }

        INLINE void * _Nonnull getNative() const SWIFT_COMPUTED_PROPERTY {
            return dataReader;
        }

    private:
        class Listener final : public eprosima::fastdds::dds::DataReaderListener {
        public:
            explicit Listener(const Callbacks &callbacks, bool loanable);
            ~Listener() override;

            // Non-copyable because it would deallocate the blocks
            Listener( const Listener& ) = delete;
            Listener& operator=( const Listener& ) = delete;

            void on_subscription_matched(_DataReader * _Nonnull reader, const eprosima::fastdds::dds::SubscriptionMatchedStatus &info) override;
            void on_data_available(_DataReader * _Nonnull reader) override;

        private:
            const bool loanable;

            onSubscriptionMatched_t subscriptionMatchedCallback;
            onData_t onDataCallback;
            onError_t onErrorCallback;
        };

        const bool loanable;

        Topic::_Topic * _Nonnull topic;
        Subscriber::_Subscriber * _Nonnull subscriber;
        _DataReader * _Nonnull dataReader;
        std::unique_ptr<Listener> listener;

        bool destroyed = false;
    } SWIFT_NONCOPYABLE SENDABLE;

}
