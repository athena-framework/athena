require "./spec_helper"

# IDK how to test the testing stuff,
# so I'll just use the example and call it good enough.

private class Calculator
  def add(v1, v2)
    v1 + v2
  end

  def substract(v1, v2)
    raise NotImplementedError.new "TODO"
  end
end

struct ExampleSpec < ASPEC::TestCase
  @target : Calculator

  def initialize : Nil
    @target = Calculator.new
  end

  def test_add : Nil
    @target.add(1, 2).should eq 3
  end

  # A pending test.
  def ptest_subtract : Nil
    @target.substract(10, 5).should eq 5
  end

  test "with macro helper" do
    @target.add(1, 2).should eq 3
  end

  test "GET /api/:slug" do
    @target.add(1, 2).should eq 3
  end

  test "123_foo bar" do
    @target.add(1, 2).should eq 3
  end
end

abstract struct SomeTypeTestCase < ASPEC::TestCase
  protected abstract def get_object : Calculator

  def test_common : Nil
    self.get_object.is_a? Calculator
  end
end

struct CalculatorTest < SomeTypeTestCase
  protected def get_object : Calculator
    Calculator.new
  end

  def test_specific : Nil
    self.get_object.add(1, 1).should eq 2
  end
end

struct DataProviderTest < ASPEC::TestCase
  @[DataProvider("get_values_hash")]
  @[DataProvider("get_values_named_tuple")]
  def test_squares(value : Int32, expected : Int32) : Nil
    (value ** 2).should eq expected
  end

  def get_values_hash : Hash
    {
      "two"   => {2, 4},
      "three" => {3, 9},
    }
  end

  def get_values_named_tuple : NamedTuple
    {
      four: {4, 16},
      five: {5, 25},
    }
  end

  @[DataProvider("get_values_array")]
  @[DataProvider("get_values_tuple")]
  def test_cubes(value : Int32, expected : Int32) : Nil
    (value ** 3).should eq expected
  end

  def get_values_array : Array
    [
      {2, 8},
      {3, 27},
    ]
  end

  def get_values_tuple : Tuple
    {
      {4, 64},
      {5, 125},
    }
  end
end

abstract struct AbstractParent < ASPEC::TestCase
  @[DataProvider("get_values")]
  def test_cubes(value : Int32, expected : Int32) : Nil
    value.should eq expected
  end

  def get_values : Tuple
    {
      {1, 1},
      {2, 2},
    }
  end
end

struct Child < AbstractParent; end
