/*
 * Block.h
 * utils
 *
 * Created by Hunter Baker on 2/28/25
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#if __has_include(<Block.h>)
# warning utils/Block.h should only be used when Block.h isn't already provided'
#endif

// This is a replacement for Block.h in the BlocksRuntime,
// because that doesn't seem to be found by SwiftPM easily on non-Darwin platforms.

#if !defined(BLOCK_EXPORT)
#   if defined(__cplusplus)
#       define BLOCK_EXPORT extern "C"
#   else
#       define BLOCK_EXPORT extern
#   endif
#endif

#if __cplusplus
extern "C" {
#endif

BLOCK_EXPORT void *_Block_copy(const void *aBlock);
BLOCK_EXPORT void _Block_release(const void *aBlock);

#if __cplusplus
}
#endif

#define Block_copy(...) ((__typeof(__VA_ARGS__))_Block_copy((const void *)(__VA_ARGS__)))
#define Block_release(...) _Block_release((const void *)(__VA_ARGS__))
