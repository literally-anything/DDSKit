/*
 * type_support.hpp
 * include
 * 
 * Created by Hunter Baker on 2/19/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <swift/bridging>

#include "common.h"

#include <fastdds/dds/topic/TypeSupport.hpp>

namespace FastDDS {

    class TypeSupportWrapper final {
    public:
        INLINE TypeSupportWrapper(eprosima::fastdds::dds::TypeSupport &&typeSupport) : typeSupport(typeSupport) {}
        INLINE TypeSupportWrapper(const eprosima::fastdds::dds::TypeSupport &typeSupport) : typeSupport(typeSupport) {}
    
        INLINE std::string getName() const SWIFT_COMPUTED_PROPERTY {
            return typeSupport.get_type_name();
        }

        INLINE bool isPlain() const SWIFT_COMPUTED_PROPERTY {
            return typeSupport.is_plain(eprosima::fastdds::dds::DataRepresentationId_t::XCDR2_DATA_REPRESENTATION);
        }

        eprosima::fastdds::dds::TypeSupport typeSupport;
    };

}
