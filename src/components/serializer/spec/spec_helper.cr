require "spec"
require "../src/athena-serializer"
require "athena-spec"

require "./models/*"

enum TestEnum
  Zero
  One
  Two
  Three
end

def get_test_property_metadata : Array(ASR::PropertyMetadataBase)
  [ASR::PropertyMetadata(String, String).new(
    name: "name",
    external_name: "external_name",
    annotation_configurations: ADI::AnnotationConfigurations.new,
    value: "YES",
    skip_when_empty: false,
    groups: ["default"],
    since_version: nil,
    until_version: nil,
  )] of ASR::PropertyMetadataBase
end

private struct TestSerializationNavigator
  include Athena::Serializer::Navigators::SerializationNavigatorInterface

  def initialize(@visitor : ASR::Visitors::SerializationVisitorInterface, @context : ASR::SerializationContext); end

  def accept(data : ASR::Serializable) : Nil
    @visitor.visit data.serialization_properties
  end

  def accept(data : _) : Nil
    @visitor.visit data
  end
end

# Asserts the output of the given *visitor_type*.
def assert_serialized_output(visitor_type : ASR::Visitors::SerializationVisitorInterface.class, expected : String, **named_args, & : ASR::Visitors::SerializationVisitorInterface -> Nil)
  io = IO::Memory.new

  visitor = visitor_type.new io, named_args
  navigator = TestSerializationNavigator.new(visitor, ASR::SerializationContext.new)
  visitor.navigator = navigator

  visitor.prepare

  yield visitor

  visitor.finish

  io.rewind.gets_to_end.should eq expected
end

# Test implementation of `ASR::Visitors::SerializationVisitorInterface` that writes the data to the `io`.
class TestSerializationVisitor
  include Athena::Serializer::Visitors::SerializationVisitorInterface

  def initialize(@io : IO, named_args : NamedTuple); end

  def assert_properties(handler : Proc(Array(ASR::PropertyMetadataBase), Nil)) : Nil
    @assert_properties = handler
  end

  def prepare : Nil
  end

  def finish : Nil
  end

  def visit(data : Array(ASR::PropertyMetadataBase)) : Nil
    @assert_properties.try &.call data
  end

  def visit(data : _) : Nil
    @io << data
  end
end

def create_serialization_visitor(&block : Array(ASR::PropertyMetadataBase) -> Nil)
  visitor = TestSerializationVisitor.new IO::Memory.new, NamedTuple.new
  visitor.assert_properties block
  visitor
end

# Test implementation of `ASR::Visitors::DeserializationVisitorInterface` that writes the data to the `io`.
class TestDeserializationVisitor
  include Athena::Serializer::Visitors::DeserializationVisitorInterface

  def initialize(@io : IO); end

  def assert_properties(handler : Proc(Array(ASR::PropertyMetadataBase), ASR::Serializable)) : Nil
    @assert_properties = handler
  end

  def prepare(data : IO | String) : ASR::Any
    ASR::Any.new ""
  end

  def finish : Nil
  end

  def visit(type : _, properties : Array(ASR::PropertyMetadataBase), data : _)
    @assert_properties.not_nil!.call properties
  end

  def visit(type : _, data : _) : Nil
    @io << data
  end
end

def create_deserialization_visitor(&block : Array(ASR::PropertyMetadataBase) -> ASR::Serializable)
  visitor = TestDeserializationVisitor.new IO::Memory.new
  visitor.assert_properties block
  visitor
end

def assert_deserialized_output(visitor_type : ASR::Visitors::DeserializationVisitorInterface.class, type : _, data : _, expected : _)
  context = ASR::DeserializationContext.new
  context.init

  visitor = visitor_type.new
  navigator = ASR::Navigators::DeserializationNavigator.new visitor, context, ASR::InstantiateObjectConstructor.new

  visitor.navigator = navigator

  result = navigator.accept type, visitor.prepare data
  result.should eq expected
end

def create_metadata(
  *,
  name : String = "name",
  external_name : String = "external_name",
  value : I = "value", skip_when_empty : Bool = false,
  groups : Array(String) = ["default"],
  since_version : String? = nil,
  until_version : String? = nil,
  annotation_configurations : ADI::AnnotationConfigurations = ADI::AnnotationConfigurations.new,
) : ASR::PropertyMetadata forall I
  context = ASR::PropertyMetadata(I, I).new name, external_name, annotation_configurations, value, skip_when_empty, groups

  context.since_version = SemanticVersion.parse since_version if since_version
  context.until_version = SemanticVersion.parse until_version if until_version

  context
end

def assert_version(*, since_version : String? = nil, until_version : String? = nil) : Bool
  ASR::ExclusionStrategies::Version.new(SemanticVersion.parse "1.0.0").skip_property?(create_metadata(since_version: since_version, until_version: until_version), ASR::SerializationContext.new)
end

def assert_groups(*, groups : Array(String), metadata_groups : Array(String) = ["default"]) : Bool
  ASR::ExclusionStrategies::Groups.new(groups).skip_property?(create_metadata(groups: metadata_groups), ASR::SerializationContext.new)
end
