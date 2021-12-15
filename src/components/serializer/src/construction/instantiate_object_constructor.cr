require "./object_constructor_interface"

# Default `ASR::ObjectConstructorInterface` implementation.
#
# Directly instantiates the object via a custom initializer added by `ASR::Serializable`.
struct Athena::Serializer::InstantiateObjectConstructor
  include Athena::Serializer::ObjectConstructorInterface

  # :inherit:
  def construct(navigator : ASR::Navigators::DeserializationNavigatorInterface, properties : Array(PropertyMetadataBase), data : ASR::Any, type)
    type.new navigator, properties, data
  end
end
