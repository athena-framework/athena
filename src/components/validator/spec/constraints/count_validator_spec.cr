require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::Count

struct CountValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint(range: (1..1), exact_message: "my_message")

    self.assert_no_violation
  end

  def three_or_less : Tuple
    {
      { {1} },
      { {1, 2} },
      { {1, 2, 3} },
      {[1]},
      {[1, 2]},
      {[1, 2, 3]},
    }
  end

  def four : Tuple
    {
      { {1, 2, 3, 4} },
      {[4, 3, 2, 1]},
    }
  end

  def five_or_more : Tuple
    {
      { {1, 2, 3, 4, 5} },
      {[5, 4, 3, 2, 1]},
    }
  end

  @[DataProvider("three_or_less")]
  def test_valid_values_max(value : Indexable) : Nil
    self.validator.validate value, self.new_constraint range: (..3)
    self.assert_no_violation
  end

  @[DataProvider("five_or_more")]
  def test_valid_values_min(value : Indexable) : Nil
    self.validator.validate value, self.new_constraint range: (5..)
    self.assert_no_violation
  end

  @[DataProvider("four")]
  def test_values_exact(value : Indexable) : Nil
    self.validator.validate value, self.new_constraint range: (4..4)
    self.assert_no_violation
  end

  @[DataProvider("five_or_more")]
  def test_invalid_values_max(value : Indexable) : Nil
    self.validator.validate value, self.new_constraint range: (..4), max_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_MANY_ERROR, value)
      .add_parameter("{{ count }}", value.size)
      .add_parameter("{{ limit }}", 4)
      .plural(4)
      .invalid_value(value)
      .assert_violation
  end

  @[DataProvider("three_or_less")]
  def test_invalid_values_min(value : Indexable) : Nil
    self.validator.validate value, self.new_constraint range: (4..), min_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_FEW_ERROR, value)
      .add_parameter("{{ count }}", value.size)
      .add_parameter("{{ limit }}", 4)
      .plural(4)
      .invalid_value(value)
      .assert_violation
  end

  @[DataProvider("five_or_more")]
  def test_invalid_values_exact_more_than_four(value : Indexable) : Nil
    self.validator.validate value, self.new_constraint range: (4..4), exact_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::NOT_EQUAL_COUNT_ERROR, value)
      .add_parameter("{{ count }}", value.size)
      .add_parameter("{{ limit }}", 4)
      .plural(4)
      .invalid_value(value)
      .assert_violation
  end

  @[DataProvider("three_or_less")]
  def test_invalid_values_exact_less_than_four(value : Indexable) : Nil
    self.validator.validate value, self.new_constraint range: (4..4), exact_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::NOT_EQUAL_COUNT_ERROR, value)
      .add_parameter("{{ count }}", value.size)
      .add_parameter("{{ limit }}", 4)
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
