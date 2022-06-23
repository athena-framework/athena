module Athena::Serializer::Visitors::SerializationVisitorInterface
  abstract def prepare : Nil
  abstract def finish : Nil

  abstract def visit(properties : Array(ASR::PropertyMetadataBase)) : Nil
  abstract def visit(data : Bool) : Nil
  abstract def visit(data : Enum) : Nil
  abstract def visit(data : Enumerable) : Nil
  abstract def visit(data : Hash) : Nil
  abstract def visit(data : ASR::Any) : Nil
  abstract def visit(data : NamedTuple) : Nil
  abstract def visit(data : Nil) : Nil
  abstract def visit(data : Number) : Nil
  abstract def visit(data : ASR::Model) : Nil
  abstract def visit(data : String) : Nil
  abstract def visit(data : Symbol) : Nil
  abstract def visit(data : Time) : Nil
  abstract def visit(data : UUID) : Nil
end
