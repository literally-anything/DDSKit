/*
 * type_support.hpp
 * include
 * 
 * Created by Hunter Baker on 2/19/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#if __has_include(<swift/bridging>)
# include <swift/bridging>
#else
# include "utils/swift_bridging.h"
#endif

#include "common.h"

#include <fastdds/dds/topic/TypeSupport.hpp>

namespace FastDDS {

    namespace Types {

        class TypeSupport final {
        public:
            using _TypeSupport = eprosima::fastdds::dds::TypeSupport;

            INLINE TypeSupport(_TypeSupport &&typeSupport) : typeSupport(typeSupport) {}
            INLINE TypeSupport(const _TypeSupport &typeSupport) : typeSupport(typeSupport) {}
        
            INLINE std::string getName() const SWIFT_COMPUTED_PROPERTY {
                return typeSupport.get_type_name();
            }

            INLINE bool isPlain() const SWIFT_COMPUTED_PROPERTY {
                return typeSupport.is_plain(eprosima::fastdds::dds::DataRepresentationId::XCDR2_DATA_REPRESENTATION);
            }
            INLINE bool isBounded() const SWIFT_COMPUTED_PROPERTY {
                return typeSupport.is_bounded();
            }

            _TypeSupport typeSupport;
        };

    }

}
