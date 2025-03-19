/*
 * fix_warnings.h
 * include
 * 
 * Created by Hunter Baker on 3/18/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

// This fixes a bunch of warnings from swift about recursive names of LocatorSelector::iterator::operator== .
// Just forward declare the class so swift doesn't get confused.
#define FASTDDS_RTPS_COMMON__LOCATORSELECTOR_HPP
namespace eprosima {
    namespace fastdds {
        namespace rtps {
            class LocatorSelector;
        }
    }
}
