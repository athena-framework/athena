require "../spec_helper"

struct ConversionTest < ASPEC::TestCase
  def test_value_not_convertible_keeps_the_cause : Nil
    cause = ::Exception.new "boom"

    AORM::Exception::ValueNotConvertible.new("foo", "foo", nil, cause).cause.should be cause
  end

  def test_value_not_convertible_shortens_long_values : Nil
    exception = AORM::Exception::ValueNotConvertible.new "a" * 33, "string"

    exception.message.should eq %(Could not convert database value "#{"a" * 20}..." to type "string".)
  end

  def test_value_not_convertible_with_a_message : Nil
    exception = AORM::Exception::ValueNotConvertible.new "foo", "json", "Unexpected token"

    exception.message.should eq %(Could not convert database value to "json" as an error was triggered by the unserialization: Unexpected token)
  end

  @[DataProvider("scalars")]
  def test_invalid_type_with_scalar(value : String | Int32 | Float64 | Bool | Nil, expected : String) : Nil
    AORM::Exception::InvalidType.new(value, "foo", ["bar", "baz"]).message.to_s.should contain expected
  end

  def scalars : Tuple
    {
      {"foo", %(value "foo")},
      {123, "value 123"},
      {-123, "value -123"},
      {12.34, "value 12.34"},
      {true, "value true"},
      {false, "value false"},
      {nil, "value nil"},
    }
  end

  @[DataProvider("non_scalars")]
  def test_invalid_type_with_non_scalar(value : Array(String) | Hash(String, String) | Time) : Nil
    AORM::Exception::InvalidType.new(value, "foo", ["bar", "baz"]).message.should eq "Could not convert value of type #{value.class} to type foo. Expected one of the following types: bar, baz."
  end

  def non_scalars : Tuple
    {
      {[] of String},
      {Hash(String, String).new},
      {Time.utc},
    }
  end

  def test_invalid_type_keeps_the_cause : Nil
    cause = ::Exception.new "boom"

    AORM::Exception::InvalidType.new("foo", "foo", ["bar", "baz"], cause).cause.should be cause
  end
end
