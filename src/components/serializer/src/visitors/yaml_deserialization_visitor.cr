class Athena::Serializer::Visitors::YAMLDeserializationVisitor < Athena::Serializer::Visitors::DeserializationVisitor
  def prepare(data : IO | String) : ASR::Any
    YAML.parse data
  end
end

# :nodoc:
def YAML::Any.deserialize(visitor : ASR::Visitors::DeserializationVisitorInterface, data : ASR::Any)
  data.as YAML::Any
end
