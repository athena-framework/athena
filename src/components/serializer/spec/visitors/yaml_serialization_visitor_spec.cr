require "../spec_helper"

# Used to conditionally add the document end marker after some scalar strings based on the libyaml version.
private def build_expected_yaml_string(expected : String) : String
  expected += "...\n" if YAML.libyaml_version < SemanticVersion.new(0, 2, 1)
  expected
end

describe ASR::Visitors::YAMLSerializationVisitor do
  describe "#visit" do
    describe "primitive types" do
      it String do
        assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, build_expected_yaml_string %(--- Foo\n)) do |visitor|
          visitor.visit "Foo"
        end
      end

      it Symbol do
        assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, build_expected_yaml_string %(--- Bar\n)) do |visitor|
          visitor.visit :Bar
        end
      end

      it Int do
        assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, build_expected_yaml_string "--- 14\n") do |visitor|
          visitor.visit 14
        end
      end

      it Float do
        assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, build_expected_yaml_string "--- 15.5\n") do |visitor|
          visitor.visit 15.5
        end
      end

      it Bool do
        assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, build_expected_yaml_string "--- false\n") do |visitor|
          visitor.visit false
        end
      end

      it Nil do
        str = "---"
        str += " " if YAML.libyaml_version < SemanticVersion.new(0, 2, 5)
        str += '\n'

        assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, build_expected_yaml_string str) do |visitor|
          visitor.visit nil
        end
      end

      it UUID do
        assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, build_expected_yaml_string "--- f89dc089-2c6c-411a-af20-ea98f90376ef\n") do |visitor|
          visitor.visit UUID.new("f89dc089-2c6c-411a-af20-ea98f90376ef")
        end
      end

      describe Enumerable do
        it Array do
          assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, "---\n- 1\n- 2\n- 3\n") do |visitor|
            visitor.visit [1, 2, 3]
          end
        end

        it Set do
          assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, "---\n- 1\n- 2\n- 3\n") do |visitor|
            visitor.visit Set{1, 2, 3}
          end
        end

        it Deque do
          assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, "---\n- 1\n- 2\n- 3\n") do |visitor|
            visitor.visit Deque{1, 2, 3}
          end
        end

        it Tuple do
          assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, "---\n- 1\n- 2\n- 3\n") do |visitor|
            visitor.visit({1, 2, 3})
          end
        end
      end

      it Time do
        assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, build_expected_yaml_string %(--- 2020-01-18T10:20:30Z\n)) do |visitor|
          visitor.visit Time.utc 2020, 1, 18, 10, 20, 30
        end
      end

      it Hash do
        assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, %(---\nkey: value\nvalues:\n- 1\n- foo\n- false\n)) do |visitor|
          visitor.visit({"key" => "value", "values" => [1, "foo", false]})
        end
      end

      it NamedTuple do
        assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, %(---\nspace key: 123.12\n)) do |visitor|
          visitor.visit({"space key": 123.12})
        end
      end

      it Enum do
        assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, build_expected_yaml_string "--- two\n") do |visitor|
          visitor.visit TestEnum::Two
        end
      end

      it YAML::Any do
        assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, build_expected_yaml_string "--- 2020\n") do |visitor|
          visitor.visit YAML.parse("2020")
        end
      end

      it JSON::Any do
        assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, build_expected_yaml_string "--- 2020\n") do |visitor|
          visitor.visit JSON.parse("2020")
        end
      end
    end

    describe ASR::Serializable do
      it "empty object" do
        assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, "--- {}\n") do |visitor|
          visitor.visit EmptyObject.new
        end
      end

      it "valid object" do
        assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, %(---\nfoo: foo\nbar: 12.1\nnest:\n  active: true\n)) do |visitor|
          visitor.visit TestObject.new
        end
      end

      it Array(ASR::PropertyMetadataBase) do
        assert_serialized_output(ASR::Visitors::YAMLSerializationVisitor, %(---\nexternal_name: YES\n)) do |visitor|
          visitor.visit get_test_property_metadata
        end
      end
    end
  end
end
