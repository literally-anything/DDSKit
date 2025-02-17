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

#ifdef DEBUG
# define INLINE inline
#else
# define INLINE inline __attribute__((always_inline))
#endif

#define SWIFT_ATTR(attr) __attribute__((swift_attr(attr)))
#define SENDABLE SWIFT_ATTR("@Sendable")
