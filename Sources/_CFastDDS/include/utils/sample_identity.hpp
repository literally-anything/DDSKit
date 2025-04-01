/*
 * sample_identity.hpp
 * include
 * 
 * Created by Hunter Baker on 2/20/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#if __has_include(<swift/bridging>)
# include <swift/bridging>
#else
# include "utils/swift_bridging.h"
#endif

#include "common.h"

#include "guid.hpp"

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

        INLINE GUID getWriterGuid() const SWIFT_COMPUTED_PROPERTY {
            return sampleIdentity.writer_guid();
        }
        INLINE uint64_t getSequenceU64Long() const SWIFT_COMPUTED_PROPERTY {
            return sampleIdentity.sequence_number().to64long();
        }
        INLINE bool getIsUnknown() const SWIFT_COMPUTED_PROPERTY {
            return sampleIdentity.sequence_number() == SequenceNumber::unknown();
        }

        _SampleIdentity sampleIdentity;
    };

}
