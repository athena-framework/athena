class Athena::Serializer::Visitors::JSONDeserializationVisitor < Athena::Serializer::Visitors::DeserializationVisitor
  def prepare(data : IO | String) : ASR::Any
    JSON.parse data
  end
end
