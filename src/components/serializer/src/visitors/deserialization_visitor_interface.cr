module Athena::Serializer::Visitors::DeserializationVisitorInterface
  abstract def prepare(data : IO | String) : ASR::Any
  abstract def visit(type : Nil.class, data : ASR::Any) : Nil
  abstract def visit(type : _, data : ASR::Any)
  abstract def visit(type : _, data : _)
end
