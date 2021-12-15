# The `ASR::Context` specific to deserialization.
class Athena::Serializer::DeserializationContext < Athena::Serializer::Context
  def direction : ASR::Context::Direction
    ASR::Context::Direction::Deserialization
  end
end
