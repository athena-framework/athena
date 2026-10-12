# Serializes the data returned from controller actions, and deserializes request bodies, on behalf of the framework.
#
# If the [Serializer bundle](/Serializer/Bundle/) is registered, the framework uses `ATH::Serializer::ComponentSerializer`, the implementation backed by the [Serializer](/Serializer/) component.
# Otherwise data is serialized via `#to_json`, and request bodies are deserialized into `JSON::Serializable` types.
module Athena::Framework::Serializer::Interface
  # Returns *data* serialized into the provided *format*, using the options from the provided *context*.
  abstract def serialize(data : _, format : String, context : ATH::View::Context) : String

  # Returns an instance of *type* deserialized from the provided *data* in the provided *format*, or `nil` if *type* is not supported.
  abstract def deserialize(data : IO, type : _, format : String)
end
