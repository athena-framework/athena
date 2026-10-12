# Serializes the data returned from controller actions, and deserializes request bodies, on behalf of the framework.
#
# `ATH::Serializer::ComponentSerializer` is the implementation backed by the [Serializer](/Serializer/) component.
module Athena::Framework::Serializer::Interface
  # Returns *data* serialized into the provided *format*, using the options from the provided *context*.
  abstract def serialize(data : _, format : String, context : ATH::View::Context) : String

  # Returns an instance of *type* deserialized from the provided *data* in the provided *format*, or `nil` if *type* is not supported.
  abstract def deserialize(data : IO, type : _, format : String)
end
