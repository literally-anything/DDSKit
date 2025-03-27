/*
 * cdr.hpp
 * types
 * 
 * Created by Hunter Baker on 3/11/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <cstdint>
#include <float.h>
#if __has_include(<swift/bridging>)
# include <swift/bridging>
#else
# include "utils/swift_bridging.h"
#endif

#include "common.h"

// Ensure that the Cdr private members are accessible
#include "private_cdr.hpp"

#include <fastcdr/Cdr.h>
#include <fastcdr/FastBuffer.h>
#include <fastcdr/CdrEncoding.hpp>
#include <fastcdr/xcdr/MemberId.hpp>
#include <fastdds/dds/topic/TopicDataType.hpp>
#include <fastdds/rtps/common/CdrSerialization.hpp>
#include <fastdds/rtps/common/SerializedPayload.hpp>

#if DBL_MANT_DIG < LDBL_MANT_DIG
# define FLOAT80_SUPPORTED
#endif

namespace FastDDS {

    namespace CDR {

        using CDRVersion = eprosima::fastcdr::CdrVersion;

        class CDRSerializer final {
        private:
            // no copy constructors
            CDRSerializer(const CDRSerializer&) = delete;
            CDRSerializer& operator=(const CDRSerializer&) = delete;

        public:
            using _CDR = eprosima::fastcdr::Cdr;
            using EncodingAlgorithmFlag = eprosima::fastcdr::EncodingAlgorithmFlag;

            INLINE CDRSerializer(
                eprosima::fastcdr::FastBuffer &cdrBuffer,
                const _CDR::Endianness endian = _CDR::DEFAULT_ENDIAN,
                const CDRVersion cdrVersion = CDRVersion::XCDRv2
            ) : cdr(cdrBuffer, endian, cdrVersion) {}

            struct State final {
                _CDR::state state;
            } SWIFT_NONCOPYABLE;
            NODISCARD INLINE State initState() const {
                return { cdr.get_state() };
            }

            NODISCARD INLINE bool beginStruct(State &state) SWIFT_NAME(beginStruct(state:)) {
                /// Replace the state with a current one.
                /// This is needed because swift doesn't understand how to move state objects around without resetting them, so we can't return them.
                state.state.~state();
                new (&state) State { cdr };

                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr.begin_serialize_type(
                        state.state,
                        cdr.get_cdr_version() == CDRVersion::XCDRv2 ? EncodingAlgorithmFlag::DELIMIT_CDR2 : EncodingAlgorithmFlag::PLAIN_CDR
                    )
                );

                return true; 
            }
            NODISCARD INLINE bool endStruct(State &previousState) SWIFT_NAME(endStruct(previousState:)) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr.end_serialize_type(previousState.state)
                );
                return true;
            }

            NODISCARD INLINE bool beginMember(const uint32_t &memberId, State &state) SWIFT_NAME(beginMember(memberId:state:)) {
                // Replace the state with a current one.
                // This is needed because swift doesn't understand how to move state objects around without resetting them, so we can't return them.
                state.state.~state();
                new (&state) State({ cdr });

                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    (cdr.*cdr.begin_serialize_member_)(memberId, true, state.state, _CDR::XCdrHeaderSelection::AUTO_WITH_SHORT_HEADER_BY_DEFAULT)
                );
                return true;
            }
            NODISCARD INLINE bool endMember(const State &previousState) SWIFT_NAME(endMember(previousState:)) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    (cdr.*cdr.end_serialize_member_)(previousState.state)
                );
                return true;
            }

            NODISCARD INLINE bool beginOptionalMember(
                const uint32_t &memberId, const bool &isPresent, State &state
            ) SWIFT_NAME(beginOptionalMember(memberId:isPresent:state:)) {
                // Replace the state with a current one.
                // This is needed because swift doesn't understand how to move state objects around without resetting them, so we can't return them.
                state.state.~state();
                new (&state) State({ cdr });

                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    (cdr.*cdr.begin_serialize_opt_member_)(memberId, isPresent, state.state, _CDR::XCdrHeaderSelection::AUTO_WITH_SHORT_HEADER_BY_DEFAULT)
                );

                if (cdr.get_cdr_version() == CDRVersion::XCDRv2 && cdr.get_encoding_flag() != EncodingAlgorithmFlag::PL_CDR2) {
                    CATCH_FOR_SWIFT(
                        eprosima::fastcdr::exception::NotEnoughMemoryException,
                        cdr.serialize(isPresent)
                    );
                }

                return true;
            }
            NODISCARD INLINE bool endOptionalMember(const State &previousState) SWIFT_NAME(endOptionalMember(previousState:)) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    (cdr.*cdr.end_serialize_opt_member_)(previousState.state)
                );
                return true;
            }


#define DEFINE_SERIALIZE_FUNCTION(type) NODISCARD INLINE bool serialize(const type &value) { \
    CATCH_FOR_SWIFT(                                                                         \
        eprosima::fastcdr::exception::NotEnoughMemoryException,                              \
        cdr.serialize(value)                                                                 \
    );                                                                                       \
    return true;                                                                             \
}
            DEFINE_SERIALIZE_FUNCTION(bool)
            DEFINE_SERIALIZE_FUNCTION(int8_t)
            DEFINE_SERIALIZE_FUNCTION(uint8_t)
            DEFINE_SERIALIZE_FUNCTION(int16_t)
            DEFINE_SERIALIZE_FUNCTION(uint16_t)
            DEFINE_SERIALIZE_FUNCTION(int32_t)
            DEFINE_SERIALIZE_FUNCTION(uint32_t)
            DEFINE_SERIALIZE_FUNCTION(int64_t)
            DEFINE_SERIALIZE_FUNCTION(uint64_t)
            DEFINE_SERIALIZE_FUNCTION(float)
            DEFINE_SERIALIZE_FUNCTION(double)
#ifdef FLOAT80_SUPPORTED
            DEFINE_SERIALIZE_FUNCTION(long double)
#endif
#undef DEFINE_SERIALIZE_FUNCTION

            NODISCARD INLINE bool serialize(const char * _Nonnull string) SWIFT_NAME(serialize(string:)) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr.serialize(string)
                );
                return true;
            }

            _CDR cdr;
        } SWIFT_UNSAFE_REFERENCE;

        class CDRDeserializer final {
        private:
            // no copy constructors
            CDRDeserializer(const CDRDeserializer&) = delete;
            CDRDeserializer& operator=(const CDRDeserializer&) = delete;

        public:
            using _CDR = eprosima::fastcdr::Cdr;
            using EncodingAlgorithmFlag = eprosima::fastcdr::EncodingAlgorithmFlag;

            using withStructCallback_t = bool (^ _Nonnull)(
                CDRDeserializer &deserializer,
                const uint32_t &memberId
            );

            INLINE CDRDeserializer(
                eprosima::fastcdr::FastBuffer &cdrBuffer,
                const _CDR::Endianness endian = _CDR::DEFAULT_ENDIAN,
                const CDRVersion cdrVersion = CDRVersion::XCDRv2
            ) : cdr(cdrBuffer, endian, cdrVersion) {}

            INLINE size_t getLastDataSize() const SWIFT_COMPUTED_PROPERTY {
                return cdr.last_data_size_;
            }
            INLINE void setLastDataSize(size_t value) SWIFT_COMPUTED_PROPERTY {
                cdr.last_data_size_ = value;
            }
            INLINE size_t getSizeRemaining() const SWIFT_COMPUTED_PROPERTY {
                return cdr.end_ - cdr.offset_;
            }
            INLINE const void * _Nonnull getCurrentOffset() const SWIFT_COMPUTED_PROPERTY {
                return cdr.offset_.current_position_;
            }
            INLINE void unsafeIncrementOffset(const uint32_t &length) {
                cdr.offset_ += length;
            }

            NODISCARD INLINE bool withStruct(NONESCAPING withStructCallback_t callback) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr.deserialize_type(
                        cdr.get_cdr_version() == CDRVersion::XCDRv2 ? EncodingAlgorithmFlag::DELIMIT_CDR2 : EncodingAlgorithmFlag::PLAIN_CDR,
                        [this, &callback](auto &_, const eprosima::fastcdr::MemberId& mid) -> bool {
                            return callback(*this, mid.id);
                        } 
                    )
                );
                return true;
            }

            NODISCARD INLINE bool setupOptional() {
                if (cdr.current_encoding_ == EncodingAlgorithmFlag::PLAIN_CDR) {
                    _CDR::state current_state(cdr);

                    eprosima::fastcdr::MemberId member_id;
                    cdr.xcdr1_deserialize_member_header(member_id, current_state);

                    auto prev_offset = cdr.offset_;
                    if (current_state.member_size_ > 0) {
                        return true;
                    } else {
                        return false;
                    }
                }
                else
                {
                    return true;
                }
            }
            /// Checks if I need to deserialize the isPresent value.
            INLINE bool checkIfOptionalHasIsPresent() {
                return cdr.cdr_version_ == CDRVersion::XCDRv2 && cdr.current_encoding_ != EncodingAlgorithmFlag::PL_CDR2;
            }

            /// This doesn't deserialize the member header, it just gets a single uint32 for a size of a sequence or string.
            NODISCARD INLINE bool deserializeRaw(uint32_t &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr.deserialize(value)
                );
                return true;
            }

#define DEFINE_DESERIALIZE_FUNCTION(type) NODISCARD INLINE bool deserialize(type &value) { \
    CATCH_FOR_SWIFT(                                                                       \
        eprosima::fastcdr::exception::NotEnoughMemoryException,                            \
        cdr.deserialize(value)                                                             \
    );                                                                                     \
    return true;                                                                           \
}
            DEFINE_DESERIALIZE_FUNCTION(bool)
            DEFINE_DESERIALIZE_FUNCTION(int8_t)
            DEFINE_DESERIALIZE_FUNCTION(uint8_t)
            DEFINE_DESERIALIZE_FUNCTION(int16_t)
            DEFINE_DESERIALIZE_FUNCTION(uint16_t)
            DEFINE_DESERIALIZE_FUNCTION(int32_t)
            DEFINE_DESERIALIZE_FUNCTION(uint32_t)
            DEFINE_DESERIALIZE_FUNCTION(int64_t)
            DEFINE_DESERIALIZE_FUNCTION(uint64_t)
            DEFINE_DESERIALIZE_FUNCTION(float)
            DEFINE_DESERIALIZE_FUNCTION(double)
#ifdef FLOAT80_SUPPORTED
            DEFINE_DESERIALIZE_FUNCTION(long double)
#endif
#undef DEFINE_DESERIALIZE_FUNCTION

            _CDR cdr;
        } SWIFT_UNSAFE_REFERENCE;

    }

}
