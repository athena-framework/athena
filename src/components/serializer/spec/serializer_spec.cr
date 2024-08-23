require "./spec_helper"

class Unserializable
  getter id : Int64?
end

class IsSerializable
  include ASR::Serializable

  getter id : Int64
end

class NotNilableModel
  include ASR::Serializable

  getter not_nilable : String
  getter not_nilable_not_serializable : Unserializable
end

class NilableModel
  include ASR::Serializable

  getter nilable : String?
  getter nilable_not_serializable : Unserializable?
end

class NilableArrayModel
  include ASR::Serializable

  getter nilable_array : Array(Unserializable)?
  getter default_array : Array(Unserializable)? = [] of Unserializable
  getter nilable_nilable_array : Array(Unserializable?)?
end

class TestingModel
  include ASR::Serializable

  getter id : Int64
  @array : Array(IsSerializable)
  property obj : IsSerializable

  def get_array
    @array
  end
end

module ReverseConverter
  def self.deserialize(navigator : ASR::Navigators::DeserializationNavigatorInterface, metadata : ASR::PropertyMetadataBase, data : ASR::Any) : String
    data.as_s.reverse
  end
end

class ReverseConverterModel
  include ASR::Serializable

  @[ASRA::Accessor(converter: ReverseConverter)]
  getter str : String
end

class SingleNilablePropertyModel
  include ASR::Serializable

  property my_prop : String?
end

abstract struct BaseModel
  include ASR::Model
end

record ModelOne < BaseModel, id : Int32, name : String do
  include ASR::Serializable
end

record ModelTwo < BaseModel, id : Int32, name : String do
  include ASR::Serializable
end

record Unionable, type : BaseModel.class

struct JSONAnyThing
  include ASR::Serializable

  getter json : Hash(String, JSON::Any)
end

struct YAMLAnyThing
  include ASR::Serializable

  getter yaml : Hash(String, YAML::Any)
end

describe ASR::Serializer do
  describe "#deserialize" do
    describe ASR::Serializable do
      describe NotNilableModel do
        it "missing" do
          ex = expect_raises ASR::Exception::MissingRequiredProperty, "Missing required property: 'not_nilable'." do
            ASR.serializer.deserialize NotNilableModel, %({}), :json
          end

          ex.property_name.should eq "not_nilable"
          ex.property_type.should eq "String"
        end

        it nil do
          ex = expect_raises ASR::Exception::NilRequiredProperty, "Required property 'not_nilable_not_serializable' cannot be nil." do
            ASR.serializer.deserialize NotNilableModel, %({"not_nilable":"FOO","not_nilable_not_serializable":null}), :json
          end

          ex.property_name.should eq "not_nilable_not_serializable"
          ex.property_type.should eq "Unserializable"
        end
      end

      describe ASRA::Accessor do
        it :setter do
          ASR.serializer.deserialize(SetterAccessor, %({"foo":"foo"}), :json).foo.should eq "FOO"
        end
      end

      describe ASRA::Discriminator do
        it "happy path" do
          ASR.serializer.deserialize(Shape, %({"x":1,"y":2,"type":"point"}), :json).should be_a Point
        end

        it "missing discriminator" do
          ex = expect_raises ASR::Exception::PropertyException, "Missing discriminator field 'type'." do
            ASR.serializer.deserialize Shape, %({"x":1,"y":2}), :json
          end

          ex.property_name.should eq "type"
        end

        it "unknown discriminator value" do
          ex = expect_raises(ASR::Exception::PropertyException, "Unknown 'type' discriminator value: 'triangle'.") do
            ASR.serializer.deserialize Shape, %({"x":1,"y":2,"type":"triangle"}), :json
          end

          ex.property_name.should eq "type"
        end
      end

      describe NilableModel do
        it "should be set to `nil`" do
          obj = ASR.serializer.deserialize NilableModel, %({"nilable":"FOO","nilable_not_serializable":{"id":10}}), :json
          obj.nilable.should eq "FOO"
          obj.nilable_not_serializable.should be_nil
        end

        it "should still return an instance if the input is empty" do
          ASR.serializer.deserialize(SingleNilablePropertyModel, "{}", :json).my_prop.should be_nil
          ASR.serializer.deserialize(SingleNilablePropertyModel, "", :yaml).my_prop.should be_nil
        end
      end

      describe NilableArrayModel do
        it "should be set to `nil` or default if not provided" do
          obj = ASR.serializer.deserialize NilableArrayModel, %({}), :json
          obj.nilable_array.should be_nil
          obj.default_array.should eq [] of Unserializable
          obj.nilable_nilable_array.should be_nil
        end

        it "should default to an empty array if provided or `nil` if possible" do
          obj = ASR.serializer.deserialize NilableArrayModel, %({"nilable_array":[{"id":1}],"default_array":[{"id":1}],"nilable_nilable_array":[{"id":1}]}), :json
          obj.nilable_array.should eq [] of Unserializable
          obj.default_array.should eq [] of Unserializable
          obj.nilable_nilable_array.should eq [nil]
        end
      end

      describe TestingModel do
        it "should deserialize correctly" do
          obj = ASR.serializer.deserialize TestingModel, %({"id":1,"array":[{"id":2},{"id":3}],"obj":{"id":4}}), :json
          obj.id.should eq 1

          array = obj.get_array
          array.size.should eq 2
          array[0].id.should eq 2
          array[1].id.should eq 3

          obj.obj.id.should eq 4
        end
      end

      describe ReverseConverterModel do
        it "should use the converter when deserializing" do
          ASR.serializer.deserialize(ReverseConverterModel, %({"str":"jim"}), :json).str.should eq "mij"
        end
      end
    end

    describe "primitive" do
      it nil do
        expect_raises ASR::Exception::DeserializationException, "Could not parse String from 'nil'." do
          ASR.serializer.deserialize String, "null", :json
        end
      end

      it Int32 do
        value = ASR.serializer.deserialize Int32, "17", :json
        value.should eq 17
        value.should be_a Int32
      end
    end

    describe Unionable do
      it "it works with a class union" do
        model = ASR.serializer.deserialize Unionable.new(ModelOne).type, %({"id":1,"name":"Fred"}), :json
        model.should be_a ModelOne
        model.id.should eq 1
        model.name.should eq "Fred"
      end
    end

    describe ASR::Any do
      it "works with base JSON type" do
        model = ASR.serializer.deserialize JSONAnyThing, %({"json":{"foo":"bar"}}), :json
        model.json.should be_a Hash(String, JSON::Any)

        model.json["foo"].as_s.should eq "bar"
      end

      it "works with base YAML type" do
        model = ASR.serializer.deserialize YAMLAnyThing, %({"yaml":{"biz":"baz"}}), :yaml
        model.yaml.should be_a Hash(String, YAML::Any)

        model.yaml["biz"].as_s.should eq "baz"
      end
    end
  end
end
