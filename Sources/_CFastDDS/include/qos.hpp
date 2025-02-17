/*
 * qos.hpp
 * include
 * 
 * Created by Hunter Baker on 2/17/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <string>
#include <swift/bridging>

#include "common.h"

#include <fastdds/dds/core/policy/QosPolicies.hpp>
#include <fastdds/dds/domain/qos/DomainParticipantQos.hpp>

namespace FastDDS {

    using eprosima::fastdds::dds::PropertyPolicyQos;
    using eprosima::fastdds::dds::DomainParticipantQos;

    namespace QOSHelpers {

        namespace PropertyPolicy {
            INLINE void addProperty(
                DomainParticipantQos &qos, const std::string &name, const std::string &value, bool propagate = false
            ) SWIFT_NAME(addProperty(to:name:value:propagate:)) {
                qos.properties().properties().emplace_back(name, value, propagate);
            }
        }

    }

}
