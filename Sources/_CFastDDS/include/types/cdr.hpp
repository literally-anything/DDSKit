/*
 * cdr.hpp
 * types
 * 
 * Created by Hunter Baker on 3/11/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <cstdint>
#include <fastcdr/exceptions/NotEnoughMemoryException.h>
#if __has_include(<swift/bridging>)
# include <swift/bridging>
#else
# include "utils/swift_bridging.h"
#endif

#include "common.h"

#include <fastcdr/CdrEncoding.hpp>
#include <fastcdr/xcdr/MemberId.hpp>
#include <fastcdr/FastBuffer.h>

// Ridiculous trick to get around the fact that fastcdr has private members that we need so we can reimplement the generic functions in swift
// Swift can't currently specialize c++ templates dircectly so we have to reimplement them in swift
#undef private
#define private public
#include <fastcdr/Cdr.h>
#undef private

#include <fastdds/dds/topic/TopicDataType.hpp>
#include <fastdds/rtps/common/CdrSerialization.hpp>
#include <fastdds/rtps/common/SerializedPayload.hpp>

#define CATCH_FOR_SWIFT_NULL(error_type, fail_return, call) \
    try { \
        call; \
    } catch (const error_type &e) { \
        return fail_return; \
    }
#define CATCH_FOR_SWIFT(error_type, call) \
    try { \
        call; \
        return true; \
    } catch (const error_type &e) { \
        return false; \
    }

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
            ) : cdr(cdrBuffer, endian, cdrVersion),
                type_encoding(cdr.get_cdr_version() == CDRVersion::XCDRv2 ? EncodingAlgorithmFlag::DELIMIT_CDR2 : EncodingAlgorithmFlag::PLAIN_CDR) {}

            struct State {
                _CDR::state state;
            };
            struct StateWithError {
                bool success;
                State state;
            };

            NODISCARD INLINE StateWithError beginStruct() {
                _CDR::state current_state(cdr);
                
                // Failure value exists only allow commas in the macro args
                #define FAILURE_VALUE { false, current_state }
                CATCH_FOR_SWIFT_NULL(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    FAILURE_VALUE,
                    cdr.begin_serialize_type(current_state, type_encoding)
                );
                #undef FAILURE_VALUE

                return { true, current_state };
            }
            NODISCARD INLINE bool endStruct(State &previousState) SWIFT_NAME(endStruct(previousState:)) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr.end_serialize_type(previousState.state)
                );
            }

            NODISCARD INLINE StateWithError beginMember(const uint32_t &memberId) {
                _CDR::state current_state(cdr);

                // Failure value exists only allow commas in the macro args
                #define FAILURE_VALUE { false, current_state }
                CATCH_FOR_SWIFT_NULL(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    FAILURE_VALUE,
                    (cdr.*cdr.begin_serialize_member_)(memberId, true, current_state, _CDR::XCdrHeaderSelection::AUTO_WITH_SHORT_HEADER_BY_DEFAULT)
                );
                #undef FAILURE_VALUE

                return { true, current_state };
            }
            NODISCARD INLINE bool endMember(const State &previousState) SWIFT_NAME(endMember(previousState:)) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    (cdr.*cdr.end_serialize_member_)(previousState.state)
                );
            }

            NODISCARD INLINE StateWithError beginOptionalMember(const uint32_t &memberId, const bool &isPresent) {
                _CDR::state current_state(cdr);

                // Failure value exists only allow commas in the macro args
                #define FAILURE_VALUE { false, current_state }
                CATCH_FOR_SWIFT_NULL(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    FAILURE_VALUE,
                    (cdr.*cdr.begin_serialize_opt_member_)(memberId, isPresent, current_state, _CDR::XCdrHeaderSelection::AUTO_WITH_SHORT_HEADER_BY_DEFAULT)
                );

                if (cdr.get_cdr_version() == CDRVersion::XCDRv2 && cdr.get_encoding_flag() != EncodingAlgorithmFlag::PL_CDR2) {
                    CATCH_FOR_SWIFT_NULL(
                        eprosima::fastcdr::exception::NotEnoughMemoryException,
                        FAILURE_VALUE,
                        cdr.serialize(isPresent)
                    );
                }
                #undef FAILURE_VALUE

                return { true, current_state };
            }
            NODISCARD INLINE bool endOptionalMember(const State &previousState) SWIFT_NAME(endOptionalMember(previousState:)) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    (cdr.*cdr.end_serialize_opt_member_)(previousState.state)
                );
            }


            NODISCARD INLINE bool serialize(const bool &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr.serialize(value)
                );
            }
            NODISCARD INLINE bool serialize(const int8_t &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr.serialize(value)
                );
            }
            NODISCARD INLINE bool serialize(const uint8_t &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr.serialize(value)
                );
            }
            NODISCARD INLINE bool serialize(const int16_t &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr.serialize(value)
                );
            }
            NODISCARD INLINE bool serialize(const uint16_t &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr.serialize(value)
                );
            }
            NODISCARD INLINE bool serialize(const int32_t &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr.serialize(value)
                );
            }
            NODISCARD INLINE bool serialize(const uint32_t &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr.serialize(value)
                );
            }
            NODISCARD INLINE bool serialize(const int64_t &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr.serialize(value)
                );
            }
            NODISCARD INLINE bool serialize(const uint64_t &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr.serialize(value)
                );
            }
            NODISCARD INLINE bool serialize(const float &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr.serialize(value)
                );
            }
            NODISCARD INLINE bool serialize(const double &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr.serialize(value)
                );
            }
            NODISCARD INLINE bool serialize(const long double &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr.serialize(value)
                );
            }

            _CDR cdr;
            const eprosima::fastcdr::EncodingAlgorithmFlag type_encoding;
        } SWIFT_UNSAFE_REFERENCE;

        class CDRDeserializer final {
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
            ) : cdr(cdrBuffer, endian, cdrVersion),
                type_encoding(cdr.get_cdr_version() == CDRVersion::XCDRv2 ? EncodingAlgorithmFlag::DELIMIT_CDR2 : EncodingAlgorithmFlag::PLAIN_CDR) {}

            //no copy constructors
            CDRDeserializer(const CDRDeserializer&) = delete;
            CDRDeserializer& operator=(const CDRDeserializer&) = delete;

            NODISCARD INLINE bool withStruct(NONESCAPING withStructCallback_t callback) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr.deserialize_type(
                        type_encoding,
                        [this, &callback](auto &_, const eprosima::fastcdr::MemberId& mid) -> bool {
                            return callback(*this, mid.id);
                        } 
                    )
                );
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

            NODISCARD INLINE bool deserialize(bool &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr >> value
                );
            }
            NODISCARD INLINE bool deserialize(int8_t &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr >> value
                );
            }
            NODISCARD INLINE bool deserialize(uint8_t &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr >> value
                );
            }
            NODISCARD INLINE bool deserialize(int16_t &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr >> value
                );
            }
            NODISCARD INLINE bool deserialize(uint16_t &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr >> value
                );
            }
            NODISCARD INLINE bool deserialize(int32_t &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr >> value
                );
            }
            NODISCARD INLINE bool deserialize(uint32_t &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr >> value
                );
            }
            NODISCARD INLINE bool deserialize(int64_t &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr >> value
                );
            }
            NODISCARD INLINE bool deserialize(uint64_t &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr >> value
                );
            }
            NODISCARD INLINE bool deserialize(float &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr >> value
                );
            }
            NODISCARD INLINE bool deserialize(double &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr >> value
                );
            }
            NODISCARD INLINE bool deserialize(long double &value) {
                CATCH_FOR_SWIFT(
                    eprosima::fastcdr::exception::NotEnoughMemoryException,
                    cdr >> value
                );
            }

            _CDR cdr;
            const eprosima::fastcdr::EncodingAlgorithmFlag type_encoding;
        } SWIFT_UNSAFE_REFERENCE;

    }

}
