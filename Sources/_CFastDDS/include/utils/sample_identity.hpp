/*
 * sample_identity.hpp
 * include
 * 
 * Created by Hunter Baker on 2/20/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <swift/bridging>

#include "common.h"

#include <cstdint>
#include <fastdds/rtps/common/SampleIdentity.hpp>

namespace FastDDS {

    // The compiler really doesn't like it if I don't make a wrapper around SampleIdentity
    class SampleIdentity final {
    public:
        using _SampleIdentity = eprosima::fastdds::rtps::SampleIdentity;
        using SequenceNumber = eprosima::fastdds::rtps::SequenceNumber_t;

        INLINE SampleIdentity() : sampleIdentity(_SampleIdentity::unknown()) {}
        INLINE SampleIdentity(_SampleIdentity &&movingIdentity) : sampleIdentity(movingIdentity) {}
        INLINE SampleIdentity(const _SampleIdentity &identity) : sampleIdentity(identity) {}

        INLINE bool operator==(const SampleIdentity& rhs) const {
            return sampleIdentity == rhs.sampleIdentity;
        }

        INLINE int32_t getHigh() const SWIFT_COMPUTED_PROPERTY {
            return sampleIdentity.sequence_number().high;
        }
        INLINE uint32_t getLow() const SWIFT_COMPUTED_PROPERTY {
            return sampleIdentity.sequence_number().low;
        }
        INLINE uint64_t getU64Long() const SWIFT_COMPUTED_PROPERTY {
            return sampleIdentity.sequence_number().to64long();
        }

        INLINE bool getIsUnknown() const SWIFT_COMPUTED_PROPERTY {
            return sampleIdentity.sequence_number() == SequenceNumber::unknown();
        }

        _SampleIdentity sampleIdentity;
    };

}
