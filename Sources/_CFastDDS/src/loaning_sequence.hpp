/*
 * loaning_sequence.hpp
 * include
 * 
 * Created by Hunter Baker on 2/19/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#pragma once

#include <fastdds/dds/core/LoanableCollection.hpp>

using LoanableCollection = eprosima::fastdds::dds::LoanableCollection;

namespace FastDDS {

    class LoaningSequence final : public LoanableCollection
    {
    public:
        using size_type = LoanableCollection::size_type;
        using element_type = LoanableCollection::element_type;

        /**
        * Default constructor.
        *
        * Creates the sequence with no data.
        *
        * @post buffer() == nullptr
        * @post has_ownership() == true
        * @post length() == 0
        * @post maximum() == 0
        */
        LoaningSequence() = default;
        ~LoaningSequence();

        LoaningSequence(const LoaningSequence& other);
        LoaningSequence& operator =(const LoaningSequence& other);

        const void * _Nullable const get(size_type index) const;

    protected:

        using LoanableCollection::maximum_;
        using LoanableCollection::length_;
        using LoanableCollection::elements_;
        bool has_ownership_ = false;

    private:

        void resize(size_type maximum) override;

        void release();

    } __attribute__((swift_private));

}
