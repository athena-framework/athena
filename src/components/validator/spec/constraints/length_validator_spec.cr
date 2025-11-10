require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::Length

struct LengthValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint(range: (1..1), exact_message: "my_message")

    self.assert_no_violation
  end

  def three_or_less : Tuple
    {
      {12, 2},
      {"12", 2},
      {"üü", 2},
      {"éé", 2},
      {123, 3},
      {"123", 3},
      {"üüü", 3},
      {"ééé", 3},
    }
  end

  def four : Tuple
    {
      {1234},
      {"1234"},
      {"üüüü"},
      {"éééé"},
    }
  end

  def five_or_more : Tuple
    {
      {12345, 5},
      {"12345", 5},
      {"üüüüü", 5},
      {"ééééé", 5},
      {123_456, 6},
      {"123456", 6},
      {"üüüüüü", 6},
      {"éééééé", 6},
    }
  end

  @[DataProvider("five_or_more")]
  def test_valid_values_min(value : Int32 | String, value_length : Int32) : Nil
    self.validator.validate value, self.new_constraint range: (5..)
    self.assert_no_violation
  end

  @[DataProvider("three_or_less")]
  def test_valid_values_max(value : Int32 | String, value_length : Int32) : Nil
    self.validator.validate value, self.new_constraint range: (..3)
    self.assert_no_violation
  end

  @[DataProvider("four")]
  def test_valid_values_exact(value : Int32 | String) : Nil
    self.validator.validate value, self.new_constraint range: (4..4)
    self.assert_no_violation
  end

  def test_valid_graphemes_values : Nil
    self.validator.validate "A\u{0300}", self.new_constraint range: (1..1), unit: CONSTRAINT::Unit::GRAPHEMES
    self.assert_no_violation
  end

  def test_valid_codepoints_values : Nil
    self.validator.validate "A\u{0300}", self.new_constraint range: (2..2), unit: CONSTRAINT::Unit::CODEPOINTS
    self.assert_no_violation
  end

  def test_valid_bytes_values : Nil
    self.validator.validate "A\u{0300}", self.new_constraint range: (3..3), unit: CONSTRAINT::Unit::BYTES
    self.assert_no_violation
  end

  @[DataProvider("three_or_less")]
  def test_invalid_values_min(value : Int32 | String, value_length : Int32) : Nil
    self.validator.validate value, self.new_constraint range: (4..), min_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_SHORT_ERROR, value)
      .add_parameter("{{ value }}", value.to_s)
      .add_parameter("{{ limit }}", 4)
      .add_parameter("{{ min }}", 4)
      .add_parameter("{{ value_length }}", value_length)
      .plural(4)
      .invalid_value(value)
      .assert_violation
  end

  @[DataProvider("five_or_more")]
  def test_invalid_values_max(value : Int32 | String, value_length : Int32) : Nil
    self.validator.validate value, self.new_constraint range: (..4), max_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_LONG_ERROR, value)
      .add_parameter("{{ value }}", value.to_s)
      .add_parameter("{{ limit }}", 4)
      .add_parameter("{{ max }}", 4)
      .add_parameter("{{ value_length }}", value_length)
      .plural(4)
      .invalid_value(value)
      .assert_violation
  end

  @[DataProvider("three_or_less")]
  def test_invalid_values_exact_less_than_four(value : Int32 | String, value_length : Int32) : Nil
    self.validator.validate value, self.new_constraint range: (4..4), exact_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::NOT_EQUAL_LENGTH_ERROR, value)
      .add_parameter("{{ value }}", value.to_s)
      .add_parameter("{{ limit }}", 4)
      .add_parameter("{{ min }}", 4)
      .add_parameter("{{ max }}", 4)
      .add_parameter("{{ value_length }}", value_length)
      .plural(4)
      .invalid_value(value)
      .assert_violation
  end

  @[DataProvider("five_or_more")]
  def test_invalid_values_exact_more_than_four(value : Int32 | String, value_length : Int32) : Nil
    self.validator.validate value, self.new_constraint range: (4..4), exact_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::NOT_EQUAL_LENGTH_ERROR, value)
      .add_parameter("{{ value }}", value.to_s)
      .add_parameter("{{ limit }}", 4)
      .add_parameter("{{ min }}", 4)
      .add_parameter("{{ max }}", 4)
      .add_parameter("{{ value_length }}", value_length)
      .plural(4)
      .invalid_value(value)
      .assert_violation
  end

  def test_invalid_values_exact_default_unit_with_grapheme_input : Nil
    self.validator.validate value = "A\u{0300}", self.new_constraint range: (1..1), exact_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::NOT_EQUAL_LENGTH_ERROR, value)
      .add_parameter("{{ value }}", value)
      .add_parameter("{{ limit }}", 1)
      .add_parameter("{{ min }}", 1)
      .add_parameter("{{ max }}", 1)
      .add_parameter("{{ value_length }}", 2)
      .plural(1)
      .invalid_value(value)
      .assert_violation
  end

  def test_invalid_values_exact_bytes_unit_with_grapheme_input : Nil
    self.validator.validate value = "A\u{0300}", self.new_constraint range: (1..1), exact_message: "my_message", unit: CONSTRAINT::Unit::BYTES

    self
      .build_violation("my_message", CONSTRAINT::NOT_EQUAL_LENGTH_ERROR, value)
      .add_parameter("{{ value }}", value)
      .add_parameter("{{ limit }}", 1)
      .add_parameter("{{ min }}", 1)
      .add_parameter("{{ max }}", 1)
      .add_parameter("{{ value_length }}", 3)
      .plural(1)
      .invalid_value(value)
      .assert_violation
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
