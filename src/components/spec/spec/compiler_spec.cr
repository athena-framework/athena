require "./spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line
    require "./spec_helper.cr"
    #{code}
    TestTestCase.run
  CR
end

describe Athena::Spec do
  describe "compiler errors", tags: "compiler" do
    describe ASPEC::TestCase::TestWith do
      describe "args" do
        it "non tuple value" do
          assert_error "Expected argument #0 of the 'ASPEC::TestCase::TestWith' annotation applied to 'TestTestCase#test_case' to be a Tuple, but got 'NumberLiteral'.", <<-CODE
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
          assert_error "Expected argument #0 of the 'ASPEC::TestCase::TestWith' annotation applied to 'TestTestCase#test_case' to contain 2 values, but got 1.", <<-CODE
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
          assert_error " Expected the value of argument 'value' of the 'ASPEC::TestCase::TestWith' annotation applied to 'TestTestCase#test_case' to be a Tuple, but got 'NumberLiteral'.", <<-CODE
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
          assert_error "Expected the value of argument 'value' of the 'ASPEC::TestCase::TestWith' annotation applied to 'TestTestCase#test_case' to contain 2 values, but got 1.", <<-CODE
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
  end
end
