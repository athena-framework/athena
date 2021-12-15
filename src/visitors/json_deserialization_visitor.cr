class Athena::Serializer::Visitors::JSONDeserializationVisitor < Athena::Serializer::Visitors::DeserializationVisitor
  def prepare(input : IO | String) : ASR::Any
    JSON.parse input
  end
end
