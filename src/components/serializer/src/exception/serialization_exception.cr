# Represents an error that occurred during serialization.
class Athena::Serializer::Exception::SerializationException < RuntimeError
  include Athena::Serializer::Exception
end
