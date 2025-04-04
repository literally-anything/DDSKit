/*
 * action_replier_contentfilter.hpp
 * include
 * 
 * Created by Hunter Baker on 4/01/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <string>

#include "common.h"
#include "participant.hpp"

#define ACTION_CONTENTFILTER_NAME "__DDSKIT_ACTION_CONTENT_FILTER__"

namespace FastDDS {
    namespace Actions {

        eprosima::fastdds::dds::ReturnCode_t registerContentFilterFactory(Participant &participant);

        INLINE std::string getContentFilterName() {
            return ACTION_CONTENTFILTER_NAME;
        }

    }
}
