require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::Size

struct SizeValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint(range: (1..1), exact_message: "my_message")

    self.assert_no_violation
  end

  def test_empty_string_is_invalid : Nil
    self.validator.validate "", self.new_constraint(range: (1..1), exact_message: "my_message")

    self
      .build_violation("my_message", CONSTRAINT::TOO_SHORT_ERROR, "")
      .add_parameter("{{ limit }}", 1)
      .add_parameter("{{ type }}", "character")
      .plural(1)
      .invalid_value("")
      .assert_violation
  end

  def three_or_less : Tuple
    {
      {"foo", "character"},
      {"12", "character"},
      {"ééé", "character"},
      { {1, 2}, "item" },
      {[3, 4], "item"},
    }
  end

  def four : Tuple
    {
      {"1234", "character"},
      {"üüüü", "character"},
      {"éééé", "character"},
      { {1, 2, 3, 4}, "item" },
      {[4, 3, 2, 1], "item"},
    }
  end

  def five_or_more : Tuple
    {
      {"12345", "character"},
      {"üüüüü", "character"},
      {"ééééé", "character"},
      { {1, 2, 3, 4, 5}, "item" },
      {[5, 4, 3, 2, 1], "item"},
    }
  end

  @[DataProvider("five_or_more")]
  def test_valid_values_min(value : String | Indexable, type : String) : Nil
    self.validator.validate value, self.new_constraint range: (5..)
    self.assert_no_violation
  end

  @[DataProvider("three_or_less")]
  def test_valid_values_max(value : String | Indexable, type : String) : Nil
    self.validator.validate value, self.new_constraint range: (..3)
    self.assert_no_violation
  end

  @[DataProvider("four")]
  def test_values_exact(value : String | Indexable, type : String) : Nil
    self.validator.validate value, self.new_constraint range: (4..4)
    self.assert_no_violation
  end

  @[DataProvider("three_or_less")]
  def test_invalid_values_min(value : String | Indexable, type : String) : Nil
    self.validator.validate value, self.new_constraint range: (4..), min_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_SHORT_ERROR, value)
      .add_parameter("{{ limit }}", 4)
      .add_parameter("{{ type }}", type)
      .plural(4)
      .invalid_value(value)
      .assert_violation
  end

  @[DataProvider("five_or_more")]
  def test_invalid_values_max(value : String | Indexable, type : String) : Nil
    self.validator.validate value, self.new_constraint range: (..4), max_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_LONG_ERROR, value)
      .add_parameter("{{ limit }}", 4)
      .add_parameter("{{ type }}", type)
      .plural(4)
      .invalid_value(value)
      .assert_violation
  end

  @[DataProvider("three_or_less")]
  def test_invalid_values_exact_less_than_four(value : String | Indexable, type : String) : Nil
    self.validator.validate value, self.new_constraint range: (4..4), exact_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_SHORT_ERROR, value)
      .add_parameter("{{ limit }}", 4)
      .add_parameter("{{ type }}", type)
      .plural(4)
      .invalid_value(value)
      .assert_violation
  end

  @[DataProvider("five_or_more")]
  def test_invalid_values_exact_more_than_four(value : String | Indexable, type : String) : Nil
    self.validator.validate value, self.new_constraint range: (4..4), exact_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_LONG_ERROR, value)
      .add_parameter("{{ limit }}", 4)
      .add_parameter("{{ type }}", type)
      .plural(4)
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
