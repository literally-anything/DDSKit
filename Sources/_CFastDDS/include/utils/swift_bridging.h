/*
 * swift_bridging.h
 * utils
 * 
 * Created by Hunter Baker on 3/01/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

// This is a replacement for swift/bridging,
// because that doesn't seem to be found by SwiftPM easily on non-Darwin platforms when the toolchain isn't installed globally.

#include "common.h"

#define _CXX_INTEROP_STRINGIFY(_x) #_x

#define SWIFT_NAME(_name) __attribute__((swift_name(#_name)))
#define SWIFT_COMPUTED_PROPERTY SWIFT_ATTR("import_computed_property")
#define SWIFT_NONCOPYABLE SWIFT_ATTR("~Copyable")
#define SWIFT_UNSAFE_REFERENCE                                          \
  __attribute__((swift_attr("import_reference")))                       \
  __attribute__((swift_attr(_CXX_INTEROP_STRINGIFY(retain:immortal))))  \
  __attribute__((swift_attr(_CXX_INTEROP_STRINGIFY(release:immortal))))
