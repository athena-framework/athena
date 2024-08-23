require "../spec_helper"

describe ASR::Visitors::YAMLDeserializationVisitor do
  describe "#visit" do
    describe "primitive types" do
      it String do
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, String, %("Foo"), "Foo"
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, String?, %("Foo"), "Foo"
      end

      it Int32 do
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Int32, "17", 17
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Int32?, "17", 17
      end

      it Int64 do
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Int64, "17", 17_i64
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Int64?, "17", 17_i64
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Int64?, "1033488268764", 1_033_488_268_764
      end

      it Float32 do
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Float32, "17.145", 17.145_f32
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Float32?, "17.145", 17.145_f32
      end

      it Float64 do
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Float64, "17.145", 17.145
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Float64?, "17.145", 17.145
      end

      it String | Int32 do
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, String | Int32, "100000", 100_000
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, String | Int32, %("Bar"), "Bar"

        expect_raises(ASR::Exception::DeserializationException, "Couldn't parse (Int32 | String) from 'false'") do
          assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, String | Int32, "false", false
        end
      end

      it Array do
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Array(Int32), "---\n- 1\n- 2\n- 3", [1, 2, 3]
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Array(Int32?), "[1,2,~]", [1, 2, nil]
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Array(Int32)?, "[1,2,3]", [1, 2, 3]
      end

      it Set do
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Set(Int32), "---\n- 1\n- 2\n- 3", Set{1, 2, 3}
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Set(Int32?), "[1,2,null]", Set{1, 2, nil}
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Set(Int32)?, "[1,2,3]", Set{1, 2, 3}
      end

      it Tuple do
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Tuple(Int32, Int32, Int32), "[1,2,3]", {1, 2, 3}
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Tuple(Int32, Int32, Int32)?, "[1,2,3]", {1, 2, 3}
      end

      it NamedTuple do
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, NamedTuple(numbers: Array(Int32), data: Hash(String, String | Int32)), %(---\nnumbers:\n  - 1\n  - 2\n  - 3\ndata:\n  name: Jim\n  age: 19), {numbers: [1, 2, 3], data: {"name" => "Jim", "age" => 19}}
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, NamedTuple(numbers: Array(Int32), data: Hash(String, String | Int32))?, %(---\nnumbers:\n  - 1\n  - 2\n  - 3\ndata:\n  name: Jim\n  age: 19), {numbers: [1, 2, 3], data: {"name" => "Jim", "age" => 19}}
      end

      it TestEnum do
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, TestEnum, "0", TestEnum::Zero
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, TestEnum, %("Three"), TestEnum::Three
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, TestEnum?, "1", TestEnum::One

        expect_raises(ASR::Exception::DeserializationException, "Couldn't parse (TestEnum | Nil) from 'asdf'") do
          assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, TestEnum?, %("asdf"), nil
        end
      end

      it Time do
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Time, %("2020-04-07T12:34:56Z"), Time.utc 2020, 4, 7, 12, 34, 56
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Time?, %("2020-04-07T12:34:56Z"), Time.utc 2020, 4, 7, 12, 34, 56
      end

      it Hash do
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Hash(String, String), %(---\nfoo: bar), {"foo" => "bar"}
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Hash(String, String)?, %(---\nfoo: bar), {"foo" => "bar"}
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Hash(String, String?)?, %(---\nfoo: bar), {"foo" => "bar"}
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Hash(String, String?), %(---\nfoo: bar), {"foo" => "bar"}
      end

      it YAML::Any do
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Hash(String, YAML::Any), %(---\nfoo: bar), {"foo" => "bar"}
        assert_deserialized_output ASR::Visitors::YAMLDeserializationVisitor, Hash(String, YAML::Any)?, %(---\nfoo: bar), {"foo" => "bar"}
      end
    end
  end
end
