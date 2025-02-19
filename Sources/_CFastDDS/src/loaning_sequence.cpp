/*
 * loaning_sequence.cpp
 * src
 * 
 * Created by Hunter Baker on 2/19/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#include "loaning_sequence.hpp"

#include <cassert>

namespace FastDDS {

    LoaningSequence::~LoaningSequence()
    {
        release();
    }

    LoaningSequence::LoaningSequence(const LoaningSequence& other)
    {
        *this = other;
    }
    LoaningSequence& LoaningSequence::operator =(const LoaningSequence& other)
    {
        release();

        LoanableCollection::length(other.length());
        const element_type* other_buf = other.buffer();
        for (size_type n = 0; n < length_; ++n)
        {
            elements_[n] = other_buf[n];
        }

        return *this;
    }

    const void * const LoaningSequence::get(size_type index) const
    {
        assert(index < length_);
        return elements_[index];
    }

    void LoaningSequence::resize(size_type maximum) {
        assert(false);
    }
    void LoaningSequence::release() {
        maximum_ = 0u;
        length_ = 0u;
        elements_ = nullptr;
        has_ownership_ = true;
    }

}
