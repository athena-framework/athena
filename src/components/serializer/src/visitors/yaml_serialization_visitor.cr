class Athena::Serializer::Visitors::YAMLSerializationVisitor
  include Athena::Serializer::Visitors::SerializationVisitorInterface

  property! navigator : Athena::Serializer::Navigators::SerializationNavigatorInterface

  def initialize(io : IO, named_args : NamedTuple) : Nil
    @builder = YAML::Builder.new io
  end

  def prepare : Nil
    @builder.start_stream
    @builder.start_document
  end

  def finish : Nil
    @builder.end_document
    @builder.end_stream
  end

  # :inherit:
  def visit(data : Array(PropertyMetadataBase)) : Nil
    @builder.mapping do
      data.each do |prop|
        @builder.scalar prop.external_name
        visit prop.value
      end
    end
  end

  def visit(data : String | Symbol | Number | Bool | Nil) : Nil
    @builder.scalar data
  end

  def visit(data : ASR::Model) : Nil
    navigator.accept data
  end

  def visit(data : Hash | NamedTuple) : Nil
    @builder.mapping do
      data.each do |key, value|
        @builder.scalar key
        visit value
      end
    end
  end

  def visit(data : Enumerable) : Nil
    @builder.sequence do
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
    @builder.scalar nil
  end
end
