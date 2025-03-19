/*
 * common.h
 * include
 * 
 * Created by Hunter Baker on 1/21/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#ifndef __cplusplus 
# error "DDSKit needs to be compiled in cxx interoperability mode, this probably means that some higher up package doesn't have the .interoperabilityMode(.cxx) flag set."
#endif

#define INLINE inline __attribute__((always_inline))
#define NODISCARD [[nodiscard("This return value needs to be checked")]]

#define SWIFT_ATTR(attr) __attribute__((swift_attr(attr)))
#define SENDABLE SWIFT_ATTR("@Sendable")
#define NONESCAPING __attribute__((noescape))

#define CATCH_FOR_SWIFT_CUSTOM(error_type, failure_return, call) \
    try { \
        call; \
    } catch (const error_type &e) { \
        return failure_return; \
    }
#define CATCH_FOR_SWIFT(error_type, call) CATCH_FOR_SWIFT_CUSTOM(error_type, false, call)
