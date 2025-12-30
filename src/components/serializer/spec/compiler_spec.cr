require "./spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, <<-CR, line: line
    require "athena-serializer"
    #{code}
  CR
end

describe Athena::Serializer, tags: "compiled" do
  describe "compiler errors" do
    describe ASRA::Name do
      it "errors if an invalid strategy is used for deserialization" do
        assert_compile_time_error "Invalid ASRA::Name strategy: ':invalid'.", <<-'CR'
          @[ASRA::Name(strategy: :invalid)]
          class Foo
            include ASR::Serializable

            def initialize; end

            property name : String = "foo"
          end

          Foo.deserialization_properties
        CR
      end
    end

    describe "read-only properties" do
      it "errors if a read-only property is not nilable and has no default value" do
        assert_compile_time_error "is read-only but is not nilable nor has a default value", <<-'CR'
          class Foo
            include ASR::Serializable

            @[ASRA::ReadOnly]
            property name : String
          end

          Foo.deserialization_properties
        CR
      end
    end
  end
end
