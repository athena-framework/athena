require "./serialization_visitor_interface"

class Athena::Serializer::Visitors::JSONSerializationVisitor
  include Athena::Serializer::Visitors::SerializationVisitorInterface

  property! navigator : Athena::Serializer::Navigators::SerializationNavigatorInterface

  def initialize(io : IO, named_args : NamedTuple) : Nil
    @builder = JSON::Builder.new io
    if indent = named_args["indent"]?
      @builder.indent = indent
    end
  end

  def prepare : Nil
    @builder.start_document
  end

  def finish : Nil
    @builder.end_document
  end

  # :inherit:
  def visit(data : Array(PropertyMetadataBase)) : Nil
    @builder.object do
      data.each do |prop|
        @builder.field(prop.external_name) do
          visit prop.value
        end
      end
    end
  end

  def visit(data : Nil) : Nil
    @builder.null
  end

  def visit(data : String | Symbol) : Nil
    @builder.string data
  end

  def visit(data : Number) : Nil
    @builder.number data
  end

  def visit(data : Bool) : Nil
    @builder.bool data
  end

  def visit(data : ASR::Model) : Nil
    navigator.accept data
  end

  def visit(data : Hash | NamedTuple) : Nil
    @builder.object do
      data.each do |key, value|
        @builder.field key.to_s do
          visit value
        end
      end
    end
  end

  def visit(data : Enumerable) : Nil
    @builder.array do
      data.each { |v| visit v }
    end
  end

  def visit(data : ASR::Any) : Nil
    visit data.raw
  end

  def visit(data : Time) : Nil
    visit data.to_rfc3339
  end

  def visit(data : Enum) : Nil
    visit data.to_s.underscore
  end

  def visit(data : UUID) : Nil
    visit data.to_s
  end

  def visit(data : _) : Nil
    # Set non serializable types to null
    @builder.null
  end
end
