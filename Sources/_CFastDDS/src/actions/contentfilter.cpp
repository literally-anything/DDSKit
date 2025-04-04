/*
 * action_contentfilter.cpp
 * src
 * 
 * Created by Hunter Baker on 4/01/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#include "actions/contentfilter.hpp"

#include "participant.hpp"

#include <fastdds/dds/log/Log.hpp>
#include <fastdds/dds/topic/IContentFilter.hpp>
#include <fastdds/dds/topic/IContentFilterFactory.hpp>

/// Gets only the replys that correspond to the requests sent in this process
class ActionContentFilter final : public eprosima::fastdds::dds::IContentFilter {
public:
    ActionContentFilter() = default;
    ~ActionContentFilter() = default;

    bool evaluate(
        const eprosima::fastdds::rtps::SerializedPayload_t &payload,
        const FilterSampleInfo &sampleInfo,
        const eprosima::fastdds::rtps::GUID_t &readerGuid
    ) const override {
        // The sample only matters if the related sample writer (the one that sends the request) is in the same process as the reader (the one that receives the reply)
        return sampleInfo.related_sample_identity.writer_guid().guidPrefix == readerGuid.guidPrefix;
    }
};

class RequestReplyContentFilterFactory final : public eprosima::fastdds::dds::IContentFilterFactory {
public:
    constexpr static const char* FILTER_NAME = ACTION_CONTENTFILTER_NAME;

    eprosima::fastdds::dds::ReturnCode_t create_content_filter(
        const char* filter_class_name,
        const char* type_name,
        const eprosima::fastdds::dds::TopicDataType* data_type,
        const char* filter_expression,
        const ParameterSeq& filter_parameters,
        eprosima::fastdds::dds::IContentFilter *&filter_instance
    ) override {
        if (0 != strcmp(filter_class_name, FILTER_NAME)) {
            return eprosima::fastdds::dds::RETCODE_BAD_PARAMETER;
        }

        filter_instance = &filterInstance;

        return eprosima::fastdds::dds::RETCODE_OK;
    }

    eprosima::fastdds::dds::ReturnCode_t delete_content_filter(
        const char* filter_class_name,
        eprosima::fastdds::dds::IContentFilter* filter_instance
    ) override {
        if (0 != strcmp(filter_class_name, FILTER_NAME)) {
            return eprosima::fastdds::dds::RETCODE_BAD_PARAMETER;
        }
        return eprosima::fastdds::dds::RETCODE_OK;
    }

private:
    ActionContentFilter filterInstance;
};

namespace FastDDS {
    namespace Actions {

        eprosima::fastdds::dds::ReturnCode_t registerContentFilterFactory(
            Participant &participant
        ) {
            // Stops two threads from registering the filter at once
            static std::mutex mutex;
            std::lock_guard<std::mutex> lock(mutex);

            // If the content filter factory is already registered, return
            if (participant.getParticipant()->lookup_content_filter_factory(RequestReplyContentFilterFactory::FILTER_NAME) != nullptr) {
                EPROSIMA_LOG_INFO(Actions.registerContentFilterFactory, "Content filter factory already registered");
                return eprosima::fastdds::dds::RETCODE_OK;
            }

            EPROSIMA_LOG_INFO(Actions.registerContentFilterFactory, "Registering content filter factory");
            return participant.getParticipant()->register_content_filter_factory(
                RequestReplyContentFilterFactory::FILTER_NAME, new RequestReplyContentFilterFactory()
            );
        }
    
    }
}
