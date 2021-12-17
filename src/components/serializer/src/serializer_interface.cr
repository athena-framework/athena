# The main entrypoint of `Athena::Serializer`.
module Athena::Serializer::SerializerInterface
  # Deserializes the provided *input_data* in the provided *format* into an instance of *type*, optionally with the provided *context*.
  abstract def deserialize(type : ASR::Model.class, data : String | IO, format : ASR::Format | String, context : ASR::DeserializationContext = ASR::DeserializationContext.new)

  # Serializes the provided *data* into *format*, optionally with the provided *context*.
  abstract def serialize(data : _, format : ASR::Format | String, context : ASR::SerializationContext = ASR::SerializationContext.new, **named_args) : String

  # Serializes the provided *data* into *format* writing it to the provided *io*, optionally with the provided *context*.=
  abstract def serialize(data : _, format : ASR::Format | String, io : IO, context : ASR::SerializationContext = ASR::SerializationContext.new, **named_args) : Nil
end
