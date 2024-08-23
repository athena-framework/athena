# Represents an error that occurred during deserialization.
class Athena::Serializer::Exception::DeserializationException < RuntimeError
  include Athena::Serializer::Exception
end
