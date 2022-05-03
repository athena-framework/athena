require "../spec_helper"

describe ASR::Visitors::JSONDeserializationVisitor do
  describe "#visit" do
    describe "primitive types" do
      it String do
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, String, %("Foo"), "Foo"
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, String?, %("Foo"), "Foo"
      end

      it Int32 do
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Int32, "17", 17
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Int32?, "17", 17
      end

      it Int64 do
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Int64, "17", 17_i64
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Int64?, "17", 17_i64
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Int64?, "1033488268764", 1_033_488_268_764
      end

      it Float32 do
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Float32, "17.145", 17.145_f32
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Float32?, "17.145", 17.145_f32
      end

      it Float64 do
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Float64, "17.145", 17.145
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Float64?, "17.145", 17.145
      end

      it String | Int32 do
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, String | Int32, "100000", 100_000
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, String | Int32, %("Bar"), "Bar"

        expect_raises(ASR::Exceptions::DeserializationException, "Couldn't parse (Int32 | String) from 'false'") do
          assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, String | Int32, "false", false
        end
      end

      it Array do
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Array(Int32), "[1,2,3]", [1, 2, 3]
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Array(Int32?), "[1,2,null]", [1, 2, nil]
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Array(Int32)?, "[1,2,3]", [1, 2, 3]
      end

      it Set do
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Set(Int32), "[1,2,3]", Set{1, 2, 3}
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Set(Int32?), "[1,2,null]", Set{1, 2, nil}
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Set(Int32)?, "[1,2,3]", Set{1, 2, 3}
      end

      it Tuple do
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Tuple(Int32, Int32, Int32), "[1,2,3]", {1, 2, 3}
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Tuple(Int32, Int32, Int32)?, "[1,2,3]", {1, 2, 3}
      end

      it NamedTuple do
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, NamedTuple(numbers: Array(Int32), data: Hash(String, String | Int32)), %({"numbers":[1,2,3],"data":{"name":"Jim","age":19}}), {numbers: [1, 2, 3], data: {"name" => "Jim", "age" => 19}}
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, NamedTuple(numbers: Array(Int32), data: Hash(String, String | Int32))?, %({"numbers":[1,2,3],"data":{"name":"Jim","age":19}}), {numbers: [1, 2, 3], data: {"name" => "Jim", "age" => 19}}
      end

      it TestEnum do
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, TestEnum, "0", TestEnum::Zero
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, TestEnum, %("Three"), TestEnum::Three
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, TestEnum?, "1", TestEnum::One

        expect_raises(ASR::Exceptions::DeserializationException, "Couldn't parse (TestEnum | Nil) from 'asdf'") do
          assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, TestEnum?, %("asdf"), nil
        end
      end

      it Time do
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Time, %("2020-04-07T12:34:56Z"), Time.utc 2020, 4, 7, 12, 34, 56
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Time?, %("2020-04-07T12:34:56Z"), Time.utc 2020, 4, 7, 12, 34, 56
      end

      it Hash do
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Hash(String, String), %({"foo": "bar"}), {"foo" => "bar"}
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Hash(String, String)?, %({"foo": "bar"}), {"foo" => "bar"}
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Hash(String, String?)?, %({"foo": "bar"}), {"foo" => "bar"}
        assert_deserialized_output ASR::Visitors::JSONDeserializationVisitor, Hash(String, String?), %({"foo": "bar"}), {"foo" => "bar"}
      end
    end
  end
end
