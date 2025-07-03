require "./spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, <<-CR, line: line
    require "./spec_helper.cr"
    #{code}
    TestTestCase.run
  CR
end

private def assert_runtime_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_runtime_error message, <<-CR, line: line
    require "./spec_helper.cr"
    #{code}
    TestTestCase.run
  CR
end

describe Athena::Spec do
  describe "compiler errors", tags: "compiled" do
    describe ASPEC::TestCase::TestWith do
      describe "args" do
        it "non tuple value" do
          assert_compile_time_error "Expected argument #0 of the 'ASPEC::TestCase::TestWith' annotation applied to 'TestTestCase#test_case' to be a Tuple, but got 'NumberLiteral'.", <<-CODE
            struct TestTestCase < ASPEC::TestCase
              @[TestWith(
                125
              )]
              def test_case(value : Int32, expected : Int32) : Nil
              end
            end
          CODE
        end

        it "argument count mismatch" do
          assert_compile_time_error "Expected argument #0 of the 'ASPEC::TestCase::TestWith' annotation applied to 'TestTestCase#test_case' to contain 2 values, but got 1.", <<-CODE
            struct TestTestCase < ASPEC::TestCase
              @[TestWith(
                {125}
              )]
              def test_case(value : Int32, expected : Int32) : Nil
              end
            end
          CODE
        end
      end

      describe "named args" do
        it "non tuple value" do
          assert_compile_time_error " Expected the value of argument 'value' of the 'ASPEC::TestCase::TestWith' annotation applied to 'TestTestCase#test_case' to be a Tuple, but got 'NumberLiteral'.", <<-CODE
            struct TestTestCase < ASPEC::TestCase
              @[TestWith(
                value: 125
              )]
              def test_case(value : Int32, expected : Int32) : Nil
              end
            end
          CODE
        end

        it "argument count mismatch" do
          assert_compile_time_error "Expected the value of argument 'value' of the 'ASPEC::TestCase::TestWith' annotation applied to 'TestTestCase#test_case' to contain 2 values, but got 1.", <<-CODE
            struct TestTestCase < ASPEC::TestCase
              @[TestWith(
                value: {125}
              )]
              def test_case(value : Int32, expected : Int32) : Nil
              end
            end
          CODE
        end
      end
    end

    describe "exception during initialize" do
      it "reports the errors once per test case" do
        assert_runtime_error "oh noes", <<-CODE
          struct TestTestCase < ASPEC::TestCase
            def initialize
              raise "oh noes"
            end

            def test_one
              1.should eq 1
            end

            def test_two
              2.should eq 2
            end
          end
        CODE
      end

      it "reports actual failing tests" do
        assert_runtime_error " Expected: 2\n            got: 1", <<-CODE
          struct TestTestCase < ASPEC::TestCase
            def test_one
              1.should eq 2
            end
          end
        CODE
      end
    end

    it "errors if defining a non-argless initializer" do
      assert_compile_time_error "`ASPEC::TestCase` initializers must be argless and non-yielding.", <<-CODE
        struct TestTestCase < ASPEC::TestCase
          def initialize(id : Int32); end
        end
        CODE
    end

    it "errors if defining a yielding initializer" do
      assert_compile_time_error "`ASPEC::TestCase` initializers must be argless and non-yielding.", <<-CODE
        struct TestTestCase < ASPEC::TestCase
          def initialize(&); end
        end
        CODE
    end
  end
end
