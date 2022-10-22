class Athena::Serializer::Visitors::JSONDeserializationVisitor < Athena::Serializer::Visitors::DeserializationVisitor
  def prepare(data : IO | String) : ASR::Any
    JSON.parse data
  end
end

# :nodoc:
def JSON::Any.deserialize(visitor : ASR::Visitors::DeserializationVisitorInterface, data : ASR::Any)
  data.as JSON::Any
end
