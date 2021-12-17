# Determines how a new object is constructed during deserialization.
#
# By default it is directly instantiated via `.new` as part of `ASR::InstantiateObjectConstructor`.
#
# However custom constructors can be defined.  A use case could be retrieving the object from the database as part of a `PUT` request in order
# to apply the deserialized data onto it.  This would allow it to retain the PK, any timestamps, or `ASRA::ReadOnly` values.
module Athena::Serializer::ObjectConstructorInterface
  # Creates an instance of *type* and applies the provided *properties* onto it, with the provided *data*.
  abstract def construct(navigator : ASR::Navigators::DeserializationNavigatorInterface, properties : Array(PropertyMetadataBase), data : ASR::Any, type)
end
