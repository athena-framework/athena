require "../spec_helper"

describe ASR::Visitors::JSONSerializationVisitor do
  describe "#visit" do
    describe "primitive types" do
      it "with indent" do
        assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, %({\n    "key": "value"\n}), indent: 4) do |visitor|
          visitor.visit({"key" => "value"})
        end
      end

      it String do
        assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, %("Foo")) do |visitor|
          visitor.visit "Foo"
        end
      end

      it Symbol do
        assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, %("Bar")) do |visitor|
          visitor.visit :Bar
        end
      end

      it Int do
        assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, "14") do |visitor|
          visitor.visit 14
        end
      end

      it Float do
        assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, "15.5") do |visitor|
          visitor.visit 15.5
        end
      end

      it Bool do
        assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, "false") do |visitor|
          visitor.visit false
        end
      end

      it Nil do
        assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, "null") do |visitor|
          visitor.visit nil
        end
      end

      it UUID do
        assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, %("f89dc089-2c6c-411a-af20-ea98f90376ef")) do |visitor|
          visitor.visit UUID.new("f89dc089-2c6c-411a-af20-ea98f90376ef")
        end
      end

      describe Enumerable do
        it Array do
          assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, "[1,2,3]") do |visitor|
            visitor.visit [1, 2, 3]
          end
        end

        it Set do
          assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, "[1,2,3]") do |visitor|
            visitor.visit Set{1, 2, 3}
          end
        end

        it Deque do
          assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, "[1,2,3]") do |visitor|
            visitor.visit Deque{1, 2, 3}
          end
        end

        it Tuple do
          assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, "[1,2,3]") do |visitor|
            visitor.visit({1, 2, 3})
          end
        end
      end

      it Time do
        assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, %("2020-01-18T10:20:30Z")) do |visitor|
          visitor.visit Time.utc 2020, 1, 18, 10, 20, 30
        end
      end

      it Hash do
        assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, %({"key":"value","values":[1,"foo",false]})) do |visitor|
          visitor.visit({"key" => "value", "values" => [1, "foo", false]})
        end
      end

      it NamedTuple do
        assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, %({"space key":123.12})) do |visitor|
          visitor.visit({"space key": 123.12})
        end
      end

      it Enum do
        assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, %("two")) do |visitor|
          visitor.visit TestEnum::Two
        end
      end

      it YAML::Any do
        assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, "2020") do |visitor|
          visitor.visit YAML.parse("2020")
        end
      end

      it JSON::Any do
        assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, "2020") do |visitor|
          visitor.visit JSON.parse("2020")
        end
      end
    end

    describe ASR::Serializable do
      it "empty object" do
        assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, "{}") do |visitor|
          visitor.visit EmptyObject.new
        end
      end

      it "valid object" do
        assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, %({"foo":"foo","bar":12.1,"nest":{"active":true}})) do |visitor|
          visitor.visit TestObject.new
        end
      end

      it Array(ASR::PropertyMetadataBase) do
        assert_serialized_output(ASR::Visitors::JSONSerializationVisitor, %({"external_name":"YES"})) do |visitor|
          visitor.visit get_test_property_metadata
        end
      end
    end
  end
end
