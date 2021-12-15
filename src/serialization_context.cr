# The `ASR::Context` specific to serialization.
#
# Allows specifying if `nil` values should be serialized.
class Athena::Serializer::SerializationContext < Athena::Serializer::Context
  # If `nil` values should be serialized.
  property? emit_nil : Bool = false

  def direction : ASR::Context::Direction
    ASR::Context::Direction::Serialization
  end
end
