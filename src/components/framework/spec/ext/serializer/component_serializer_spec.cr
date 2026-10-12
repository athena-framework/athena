require "../../spec_helper"

private record JSONSerializableEntity, id : Int32 do
  include JSON::Serializable
end

private record ASRSerializableEntity, id : Int32 do
  include ASR::Serializable
end

private record ASRAndJSONSerializableEntity, id : Int32 do
  include ASR::Serializable
  include JSON::Serializable

  @[ASRA::Name(key: "ID")]
  @id : Int32
end

private class ContextEntity
  include ASR::Serializable

  @[ASRA::Groups("one")]
  getter id : Int32 = 1

  @[ASRA::Groups("two")]
  getter name : String = "Fred"

  @[ASRA::Groups("one")]
  @[ASRA::Since("2.0.0")]
  getter added : String = "new"

  @[ASRA::Groups("one")]
  getter nickname : String? = nil

  def initialize; end
end

private class NotSerializable; end

struct ComponentSerializerTest < ASPEC::TestCase
  @serializer : ATH::Serializer::ComponentSerializer

  def initialize
    @serializer = ATH::Serializer::ComponentSerializer.new ASR::Serializer.new
  end

  def test_serialize_json_serializable : Nil
    @serializer.serialize(JSONSerializableEntity.new(1), "json", ATH::View::Context.new).should eq %({"id":1})
  end

  def test_serialize_prefers_asr_serializable : Nil
    @serializer.serialize(ASRAndJSONSerializableEntity.new(1), "json", ATH::View::Context.new).should eq %({"ID":1})
  end

  def test_serialize_default_context : Nil
    @serializer.serialize(ContextEntity.new, "json", ATH::View::Context.new).should eq %({"id":1,"name":"Fred","added":"new"})
  end

  def test_serialize_converts_context : Nil
    context = ATH::View::Context.new
    context.groups = {"one"}
    context.version = "1.0.0"
    context.emit_nil = true

    @serializer.serialize(ContextEntity.new, "json", context).should eq %({"id":1,"nickname":null})
  end

  def test_serialize_unserializable : Nil
    expect_raises AHK::Exception::Logic, "Failed to serialize response body. Did you forget to include either `JSON::Serializable` or `ASR::Serializable`?" do
      @serializer.serialize NotSerializable.new, "json", ATH::View::Context.new
    end
  end

  def test_deserialize_asr_serializable : Nil
    object = @serializer.deserialize IO::Memory.new(%({"id":10})), ASRSerializableEntity, "json"
    object = object.should be_a ASRSerializableEntity

    object.id.should eq 10
  end

  def test_deserialize_json_serializable : Nil
    object = @serializer.deserialize IO::Memory.new(%({"id":10})), JSONSerializableEntity, "json"
    object = object.should be_a JSONSerializableEntity

    object.id.should eq 10
  end

  def test_deserialize_prefers_asr_serializable : Nil
    object = @serializer.deserialize IO::Memory.new(%({"ID":10})), ASRAndJSONSerializableEntity, "json"
    object = object.should be_a ASRAndJSONSerializableEntity

    object.id.should eq 10
  end

  def test_deserialize_asr_serializable_malformed : Nil
    expect_raises AHK::Exception::BadRequest, "Malformed JSON payload." do
      @serializer.deserialize IO::Memory.new(%({"id":"foo"})), ASRSerializableEntity, "json"
    end
  end

  def test_deserialize_unsupported : Nil
    @serializer.deserialize(IO::Memory.new(%("foo")), String, "json").should be_nil
  end
end
