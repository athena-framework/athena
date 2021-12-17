class Athena::Serializer::Visitors::YAMLDeserializationVisitor < Athena::Serializer::Visitors::DeserializationVisitor
  def prepare(input : IO | String) : ASR::Any
    YAML.parse input
  end
end
