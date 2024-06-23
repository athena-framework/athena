require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::Range

struct RangeValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint range: 0..10
    self.assert_no_violation
  end

  @[DataProvider("ten_to_twenty")]
  def test_valid_values_min(value : Number?) : Nil
    self.validator.validate value, self.new_constraint range: (10..)
    self.assert_no_violation
  end

  @[DataProvider("ten_to_twenty")]
  def test_valid_values_max(value : Number?) : Nil
    self.validator.validate value, self.new_constraint range: (..20)
    self.assert_no_violation
  end

  @[DataProvider("ten_to_twenty")]
  def test_valid_values_minmax(value : Number?) : Nil
    self.validator.validate value, self.new_constraint range: (10..20)
    self.assert_no_violation
  end

  @[DataProvider("less_than_ten")]
  def test_invalid_values_min(value : Number?) : Nil
    self.validator.validate value, self.new_constraint range: (10..), min_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_LOW_ERROR, value)
      .add_parameter("{{ limit }}", 10)
      .assert_violation
  end

  @[DataProvider("more_than_twenty")]
  def test_invalid_values_max(value : Number?) : Nil
    self.validator.validate value, self.new_constraint range: (..20), max_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_HIGH_ERROR, value)
      .add_parameter("{{ limit }}", 20)
      .assert_violation
  end

  @[DataProvider("more_than_twenty")]
  def test_invalid_values_minmax_max(value : Number?) : Nil
    self.validator.validate value, self.new_constraint range: (10..20), not_in_range_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::NOT_IN_RANGE_ERROR, value)
      .add_parameter("{{ min }}", 10)
      .add_parameter("{{ max }}", 20)
      .assert_violation
  end

  @[DataProvider("less_than_ten")]
  def test_invalid_values_minmax_min(value : Number?) : Nil
    self.validator.validate value, self.new_constraint range: (10..20), not_in_range_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::NOT_IN_RANGE_ERROR, value)
      .add_parameter("{{ min }}", 10)
      .add_parameter("{{ max }}", 20)
      .assert_violation
  end

  def test_exclusive_range_included : Nil
    self.validator.validate 15, self.new_constraint range: (10...20)
    self.assert_no_violation
  end

  def test_exclusive_range_excluded : Nil
    self.validator.validate 20, self.new_constraint range: (10...20), not_in_range_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::NOT_IN_RANGE_ERROR, 20)
      .add_parameter("{{ min }}", 10)
      .add_parameter("{{ max }}", 19)
      .assert_violation
  end

  @[DataProvider("ten_to_twnentieth_april_2020")]
  def test_valid_datetimes_min(value : Time) : Nil
    self.validator.validate value, self.new_constraint range: (Time.utc(2020, 4, 10)..)
    self.assert_no_violation
  end

  @[DataProvider("ten_to_twnentieth_april_2020")]
  def test_valid_datetimes_min(value : Time) : Nil
    self.validator.validate value, self.new_constraint range: (..Time.utc(2020, 4, 20))
    self.assert_no_violation
  end

  @[DataProvider("ten_to_twnentieth_april_2020")]
  def test_valid_datetimes_min(value : Time) : Nil
    self.validator.validate value, self.new_constraint range: (Time.utc(2020, 4, 10)..Time.utc(2020, 4, 20))
    self.assert_no_violation
  end

  @[DataProvider("before_tenth_april_2020")]
  def test_invalid_datetimes_min(value : Time) : Nil
    expected_start_date = Time.utc(2020, 4, 10)

    self.validator.validate value, self.new_constraint range: (expected_start_date..), min_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_LOW_ERROR, value)
      .add_parameter("{{ limit }}", expected_start_date)
      .assert_violation
  end

  @[DataProvider("after_twentieth_april_2020")]
  def test_invalid_datetimes_max(value : Time) : Nil
    expected_end_date = Time.utc(2020, 4, 20)

    self.validator.validate value, self.new_constraint range: (..expected_end_date), max_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::TOO_HIGH_ERROR, value)
      .add_parameter("{{ limit }}", expected_end_date)
      .assert_violation
  end

  @[DataProvider("after_twentieth_april_2020")]
  def test_invalid_datetimes_minmax_max(value : Time) : Nil
    expected_begin_date = Time.utc(2020, 4, 10)
    expected_end_date = Time.utc(2020, 4, 20)

    self.validator.validate value, self.new_constraint range: (expected_begin_date..expected_end_date), not_in_range_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::NOT_IN_RANGE_ERROR, value)
      .add_parameter("{{ min }}", expected_begin_date)
      .add_parameter("{{ max }}", expected_end_date)
      .assert_violation
  end

  @[DataProvider("before_tenth_april_2020")]
  def test_invalid_datetimes_minmax_min(value : Time) : Nil
    expected_begin_date = Time.utc(2020, 4, 10)
    expected_end_date = Time.utc(2020, 4, 20)

    self.validator.validate value, self.new_constraint range: (expected_begin_date..expected_end_date), not_in_range_message: "my_message"

    self
      .build_violation("my_message", CONSTRAINT::NOT_IN_RANGE_ERROR, value)
      .add_parameter("{{ min }}", expected_begin_date)
      .add_parameter("{{ max }}", expected_end_date)
      .assert_violation
  end

  def test_invalid_type : Nil
    expect_raises AVD::Exception::UnexpectedValueError, "Expected argument of type 'Number | Time', 'Bool' given." do
      self.validator.validate false, self.new_constraint range: (10..20)
    end
  end

  def ten_to_twenty : Tuple
    {
      {10.000_01},
      {19.999_99},
      {10},
      {20},
      {20_i64},
      {10.0},
      {10.0_f32},
      {20.0},
      {nil},
    }
  end

  def less_than_ten : Tuple
    {
      {9.999_99},
      {5},
      {1.0},
    }
  end

  def more_than_twenty : Tuple
    {
      {20.000_001},
      {21},
      {30.0},
    }
  end

  def ten_to_twnentieth_april_2020 : Tuple
    {
      {Time.utc(2020, 4, 10)},
      {Time.utc(2020, 4, 15)},
      {Time.utc(2020, 4, 20)},
    }
  end

  def before_tenth_april_2020 : Tuple
    {
      {Time.utc(2019, 4, 20)},
      {Time.utc(2020, 4, 9)},
    }
  end

  def after_twentieth_april_2020 : Tuple
    {
      {Time.utc(2020, 4, 21)},
      {Time.utc(2021, 4, 9)},
    }
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
