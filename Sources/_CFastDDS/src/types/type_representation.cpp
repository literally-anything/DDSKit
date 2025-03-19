/*
 * type_representation.cpp
 * types
 * 
 * Created by Hunter Baker on 3/18/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#include "types/type_representation.hpp"

namespace FastDDS {

    namespace Types {

        void debugCheckForIdenticalRegistered(const CompleteStructType &completeType, TypeIdentifierPair &identifiers, bool &identicalRegistered) {
#if defined(DEBUG) && DEBUG == 1
            std::string name = completeType.header().detail().type_name().to_string();

            // Check if the type is already registered and is identical
            TypeIdentifierPair foundIdentifiers;
            if (getIdentifiersForName(name, foundIdentifiers)) {
                eprosima::fastdds::dds::xtypes::TypeObject foundType;
                auto ret = eprosima::fastdds::dds::DomainParticipantFactory::get_instance()->type_object_registry().get_type_object(
                    foundIdentifiers.pair.type_identifier2(), foundType
                );

                if (ret == eprosima::fastdds::dds::RETCODE_OK) {
                    try {
                        if (foundType.complete().struct_type() == completeType) {
                            identicalRegistered = true;
                            EPROSIMA_LOG_INFO(Types.finishStruct, "Type already registered, but identical: " << name);
                            identifiers.pair = foundIdentifiers.pair;
                        }
                    } catch (const eprosima::fastcdr::exception::BadParamException &e) {}
                }
            }
#endif
        }

    }

}
