module Athena::Serializer::Navigators::NavigatorFactoryInterface
  abstract def get_serialization_navigator(visitor : ASR::Visitors::SerializationVisitorInterface, context : ASR::SerializationContext) : ASR::Navigators::SerializationNavigatorInterface
  abstract def get_deserialization_navigator(visitor : ASR::Visitors::DeserializationVisitorInterface, context : ASR::DeserializationContext) : ASR::Navigators::DeserializationNavigatorInterface
end

struct Athena::Serializer::Navigators::NavigatorFactory
  include Athena::Serializer::Navigators::NavigatorFactoryInterface

  def initialize(@object_constructor : ASR::ObjectConstructorInterface = ASR::InstantiateObjectConstructor.new); end

  def get_serialization_navigator(visitor : ASR::Visitors::SerializationVisitorInterface, context : ASR::SerializationContext) : ASR::Navigators::SerializationNavigatorInterface
    ASR::Navigators::SerializationNavigator.new visitor, context
  end

  def get_deserialization_navigator(visitor : ASR::Visitors::DeserializationVisitorInterface, context : ASR::DeserializationContext) : ASR::Navigators::DeserializationNavigatorInterface
    ASR::Navigators::DeserializationNavigator.new visitor, context, @object_constructor
  end
end
