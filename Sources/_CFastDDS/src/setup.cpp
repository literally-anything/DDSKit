/*
 * setup.cpp
 * src
 * 
 * Created by Hunter Baker on 2/18/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#include "setup.hpp"

#include <mutex>

#include "logging.hpp"

#include <fastdds/LibrarySettings.hpp>
#include <fastdds/dds/core/ReturnCode.hpp>
#include <fastdds/dds/domain/DomainParticipantFactory.hpp>

using eprosima::fastdds::LibrarySettings;
using namespace eprosima::fastdds::dds;

namespace FastDDS {

    int32_t setup(
        LogCallback_t logCallback
    ) {
        static std::mutex mutex;
        std::lock_guard<std::mutex> lock(mutex);

        // Ensure that log setup is only actually run once successfully
        static bool setup_done = false;
        if (!setup_done) {
            FastDDS::initLogging(logCallback);
            setup_done = true;
        }

        // The factory should non auto enable participants
        eprosima::fastdds::dds::DomainParticipantFactoryQos factoryQos;
        DomainParticipantFactory::get_instance()->get_qos(factoryQos);
        factoryQos.entity_factory().autoenable_created_entities = false;
        auto setFactoryQosRet = DomainParticipantFactory::get_instance()->set_qos(factoryQos);
        if (setFactoryQosRet != RETCODE_OK) {
            EPROSIMA_LOG_WARNING(Setup, "Failed to set participant factory QoS");
            return setFactoryQosRet;
        }

        // The participants should not auto enable other entities
        eprosima::fastdds::dds::DomainParticipantQos qos = DomainParticipantFactory::get_instance()->get_default_participant_qos();
        qos.entity_factory().autoenable_created_entities = false;
        auto setDefaultQosRet = DomainParticipantFactory::get_instance()->set_default_participant_qos(qos);
        if (setDefaultQosRet != RETCODE_OK) {
            EPROSIMA_LOG_WARNING(Setup, "Failed to set default participant QoS");
            return setDefaultQosRet;
        }

        return RETCODE_OK;
    }

}

void FastDDS::setIntraProcessDelivery(bool enabled) {
    LibrarySettings library_settings;
    DomainParticipantFactory::get_instance()->get_library_settings(library_settings);
    library_settings.intraprocess_delivery = enabled ? eprosima::fastdds::INTRAPROCESS_FULL : eprosima::fastdds::INTRAPROCESS_OFF;
    DomainParticipantFactory::get_instance()->set_library_settings(library_settings);
}
