/*
 * data_writer.hpp
 * include
 * 
 * Created by Hunter Baker on 2/04/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <cstdint>
#include <swift/bridging>

#include "common.h"
#include "topic.hpp"
#include "publisher.hpp"

#include <fastdds/dds/publisher/DataWriter.hpp>
#include <fastdds/dds/publisher/DataWriterListener.hpp>
#include <fastdds/dds/publisher/qos/DataWriterQos.hpp>

namespace FastDDS {

    class DataWriter final {
    public:
        using _DataWriter = eprosima::fastdds::dds::DataWriter;
        using DataWriterQos = eprosima::fastdds::dds::DataWriterQos;
        using StatusMask = eprosima::fastdds::dds::StatusMask;


        using onPublicationMatched_t = void (^ SENDABLE _Nonnull)(int32_t matchCount, int32_t countChange);
        struct Callbacks {
            onPublicationMatched_t publicationMatchedCallback;
        };


        class Qos final {
        public:
            INLINE Qos(const Publisher &publisherWrapper) SWIFT_NAME(init(publisher:)) {
                qos = publisherWrapper.publisher->get_default_datawriter_qos();
            }

            INLINE void setOperatingMode(bool push) SWIFT_NAME(setOperatingMode(push:)) {
                qos.properties().properties().emplace_back("fastdds.push_mode", push ? "true" : "false");
            }
            INLINE void setDataSharingModeOn(const char * _Nonnull dir) SWIFT_NAME(setDataSharingMode(dir:)) {
                qos.data_sharing().on(dir);
            }
            INLINE void setDataSharingModeOff() {
                qos.data_sharing().off();
            }

            INLINE const DataWriterQos &get() const {
                return qos;
            }

        private:
            DataWriterQos qos;
        };


        INLINE DataWriter(
            const Topic &topicWrapper, const Publisher &publisherWrapper,
            const std::string &profileName,
            bool &success
        ) SWIFT_NAME(init(topic:publisher:profile:success:)) : topic(topicWrapper.topic), publisher(publisherWrapper.publisher) {
            dataWriter = publisher->create_datawriter_with_profile(topic, profileName, nullptr, StatusMask::none());
            success = dataWriter != nullptr;
            destroyed = !success;
        }

        INLINE DataWriter(
            const Topic &topicWrapper, const Publisher &publisherWrapper,
            const Qos &qos,
            bool &success
        ) SWIFT_NAME(init(topic:publisher:profile:success:)) : topic(topicWrapper.topic), publisher(publisherWrapper.publisher) {
            dataWriter = publisher->create_datawriter(topic, qos.get(), nullptr, StatusMask::none());
            success = dataWriter != nullptr;
            destroyed = !success;
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t enable() {
            return dataWriter->enable();
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t setCallbacks(const Callbacks &callbacks) {
            listener = std::make_unique<Listener>(callbacks);
            return dataWriter->set_listener(listener.get(), StatusMask::publication_matched());
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t destroy() {
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


        INLINE int32_t getMatchedCount() const SWIFT_COMPUTED_PROPERTY {
            eprosima::fastdds::dds::PublicationMatchedStatus status;
            dataWriter->get_publication_matched_status(status);
            return status.current_count;
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t write(const void * _Nonnull const data) SWIFT_NAME(write(data:)) {
            return dataWriter->write(data);
        }

        static INLINE int getLoanInitKindNone() {
            return static_cast<std::underlying_type_t<_DataWriter::LoanInitializationKind>>(
                _DataWriter::LoanInitializationKind::NO_LOAN_INITIALIZATION
            );
        }
        static INLINE int getLoanInitKindZero() {
            return static_cast<std::underlying_type_t<_DataWriter::LoanInitializationKind>>(
                _DataWriter::LoanInitializationKind::ZERO_LOAN_INITIALIZATION
            );
        }
        static INLINE int getLoanInitKindConstructed() {
            return static_cast<std::underlying_type_t<_DataWriter::LoanInitializationKind>>(
                _DataWriter::LoanInitializationKind::CONSTRUCTED_LOAN_INITIALIZATION
            );
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t loan(
            void * _Nullable &data, int initKind
        ) SWIFT_NAME(loan(dataPtr:initKind:)) {
            return dataWriter->loan_sample(data, static_cast<_DataWriter::LoanInitializationKind>(initKind));
        }

        NODISCARD INLINE eprosima::fastdds::dds::ReturnCode_t discardLoan(void * _Nonnull &data) SWIFT_NAME(discardLoan(dataPtr:)) {
            return dataWriter->discard_loan(data);
        }

    private:
        class Listener final : public eprosima::fastdds::dds::DataWriterListener {
        public:
            explicit Listener(const Callbacks &callbacks);
            ~Listener() override;

            // Non-copyable because it would deallocate the blocks
            Listener( const Listener& ) = delete;
            Listener& operator=( const Listener& ) = delete;

            void on_publication_matched(_DataWriter * _Nonnull writer, const eprosima::fastdds::dds::PublicationMatchedStatus &info) override;

        private:
            onPublicationMatched_t publicationMatchedCallback;
        };

        Topic::_Topic * _Nonnull topic;
        Publisher::_Publisher * _Nonnull publisher;
        _DataWriter * _Nonnull dataWriter;
        std::unique_ptr<Listener> listener;

        bool destroyed = false;
    } SWIFT_NONCOPYABLE;

}
