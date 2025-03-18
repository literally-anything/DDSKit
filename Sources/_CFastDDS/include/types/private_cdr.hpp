/*
 * private_cdr.hpp
 * types
 * 
 * Created by Hunter Baker on 3/18/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

namespace eprosima {
    namespace fastcdr {
        class Cdr;
        class CdrSizeCalculator;
    }
}

// Ridiculous trick to get around the fact that fastcdr has private members that we need so we can reimplement the generic functions in swift
// Swift can't currently specialize c++ templates dircectly so we have to reimplement them in swift
#undef private
#define private public
#include <fastcdr/Cdr.h>
#include <fastcdr/CdrSizeCalculator.hpp>
#undef private
