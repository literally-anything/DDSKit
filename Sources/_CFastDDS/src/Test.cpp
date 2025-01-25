#include "old/Test.hpp"

#include "fastdds/dds/subscriber/Subscriber.hpp"
#include "fastdds/dds/subscriber/DataReader.hpp"
#include "fastdds/dds/publisher/Publisher.hpp"
#include "fastdds/dds/publisher/DataWriter.hpp"
#include "fastdds/dds/xtypes/dynamic_types/DynamicData.hpp"
#include "fastdds/dds/xtypes/dynamic_types/DynamicDataFactory.hpp"
#include "fastdds/dds/xtypes/dynamic_types/DynamicType.hpp"
#include "fastdds/dds/xtypes/dynamic_types/DynamicTypeBuilder.hpp"
#include "fastdds/dds/xtypes/dynamic_types/DynamicTypeBuilderFactory.hpp"
#include "fastdds/dds/xtypes/dynamic_types/TypeDescriptor.hpp"
#include "fastdds/dds/xtypes/dynamic_types/MemberDescriptor.hpp"

using namespace eprosima::fastdds::dds;

DynamicType::_ref_type create_type()
{
    TypeDescriptor::_ref_type type_descriptor {traits<TypeDescriptor>::make_shared()};
    type_descriptor->kind(TK_STRUCTURE);
    type_descriptor->name("HelloWorld");
    auto struct_builder = DynamicTypeBuilderFactory::get_instance()->create_type(type_descriptor);
    if (!struct_builder)
    {
        throw std::runtime_error("Error creating type builder");
    }

    // Add index member
    MemberDescriptor::_ref_type index_member_descriptor {traits<MemberDescriptor>::make_shared()};
    index_member_descriptor->name("index");
    index_member_descriptor->type(DynamicTypeBuilderFactory::get_instance()->get_primitive_type(TK_UINT32));

    if (RETCODE_OK != struct_builder->add_member(index_member_descriptor))
    {
        throw std::runtime_error("Error adding index member");
    }

    // Add message member
    // MemberDescriptor::_ref_type message_member_descriptor {traits<MemberDescriptor>::make_shared()};
    // message_member_descriptor->name("message");
    // message_member_descriptor->type(DynamicTypeBuilderFactory::get_instance()->create_string_type(static_cast<
    //             uint32_t>(
    //             LENGTH_UNLIMITED))->build());

    // if (!message_member_descriptor)
    // {
    //     throw std::runtime_error("Error creating string type");
    // }

    // if (RETCODE_OK != struct_builder->add_member(message_member_descriptor))
    // {
    //     throw std::runtime_error("Error adding message member");
    // }

    // Build the type
    return struct_builder->build();
}

void doit(fastdds::_DomainParticipant::DomainParticipant *participant) {
    auto dyntype = create_type();
    if (!dyntype)
    {
        std::cout << "Error creating dynamic type" << std::endl;
        throw std::runtime_error("Error creating dynamic type");
    }

    DynamicData::_ref_type hello = DynamicDataFactory::get_instance()->create_data(dyntype);
    if (!hello)
    {
        std::cout << "Error creating dynamic data" << std::endl;
        throw std::runtime_error("Error creating dynamic data");
    }
    hello->set_uint32_value(hello->get_member_id_by_name("index"), 0);
    // hello->set_string_value(hello->get_member_id_by_name("message"), "Hello xtypes world");

    TypeSupport type(new DynamicPubSubType(dyntype));
    if (RETCODE_OK != type.register_type(participant))
    {
        throw std::runtime_error("Type registration failed");
    }

    PublisherQos pub_qos = PUBLISHER_QOS_DEFAULT;
    participant->get_default_publisher_qos(pub_qos);
    auto publisher_ = participant->create_publisher(pub_qos);
    if (publisher_ == nullptr)
    {
        throw std::runtime_error("Publisher initialization failed");
    }

    SubscriberQos sub_qos = SUBSCRIBER_QOS_DEFAULT;
    participant->get_default_subscriber_qos(sub_qos);
    auto subscriber_ = participant->create_subscriber(sub_qos);
    if (nullptr == subscriber_)
    {
        throw std::runtime_error("Subscriber initialization failed");
    }

    TopicQos topic_qos = TOPIC_QOS_DEFAULT;
    participant->get_default_topic_qos(topic_qos);
    auto topic_ = participant->create_topic("hello", type.get_type_name(), topic_qos);
    if (topic_ == nullptr)
    {
        throw std::runtime_error("Topic initialization failed");
    }

    DataWriterQos writer_qos = DATAWRITER_QOS_DEFAULT;
    publisher_->get_default_datawriter_qos(writer_qos);
    auto writer_ = publisher_->create_datawriter(topic_, writer_qos, nullptr, StatusMask::all());
    if (writer_ == nullptr)
    {
        throw std::runtime_error("DataWriter initialization failed");
    }

    DataReaderQos reader_qos = DATAREADER_QOS_DEFAULT;
    subscriber_->get_default_datareader_qos(reader_qos);
    auto reader_ = subscriber_->create_datareader(topic_, reader_qos);
    if (nullptr == reader_)
    {
        throw std::runtime_error("DataReader initialization failed");
    }

    std::cout << "Writing" << std::endl;
    if (RETCODE_OK != writer_->write(&hello)) {
    // if (RETCODE_OK != writer_->write(participant)) {
        throw std::runtime_error("Could not write");
    }
    std::cout << "Done" << std::endl;

    participant->delete_contained_entities();
}
