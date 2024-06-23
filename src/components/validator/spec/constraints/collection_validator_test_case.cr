require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::Collection

abstract struct CollectionValidatorTestCase < AVD::Spec::ConstraintValidatorTestCase
  private abstract def prepare_test_data(contents : Hash)

  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint fields: {"foo" => AVD::Constraints::NotBlank.new}
    self.assert_no_violation
  end

  def test_invalid_type : Nil
    expect_raises AVD::Exception::UnexpectedValueError, "Expected argument of type 'Enumerable({K, V})', 'String' given." do
      self.validator.validate "foobar", self.new_constraint fields: {"foo" => AVD::Constraints::NotBlank.new}
    end
  end

  def test_walks_single_constraint : Nil
    constraint = AVD::Constraints::Range.new 4..

    data = {
      "foo" => 3,
      "bar" => 5,
    }

    idx = 0

    data.each do |k, v|
      self.expect_validate_value_at idx, "[#{k}]", v, [constraint]
      idx += 1
    end

    data = self.prepare_test_data data

    self.validator.validate data, self.new_constraint fields: {
      "foo" => constraint,
      "bar" => constraint,
    }

    self.assert_no_violation
  end

  def test_walks_multiple_constraints : Nil
    constraints = [
      AVD::Constraints::Range.new(4..),
      AVD::Constraints::NotNil.new,
    ]

    data = {
      "foo" => 3,
      "bar" => 5,
    }

    idx = 0

    data.each do |k, v|
      self.expect_validate_value_at idx, "[#{k}]", v, constraints
      idx += 1
    end

    data = self.prepare_test_data data

    self.validator.validate data, self.new_constraint fields: {
      "foo" => constraints,
      "bar" => constraints,
    }

    self.assert_no_violation
  end

  def test_extra_fields_disallowed : Nil
    constraint = AVD::Constraints::Range.new(4..)

    data = self.prepare_test_data({
      "foo" => 5,
      "baz" => 6,
    })

    self.expect_validate_value_at 0, "[foo]", data["foo"], [constraint]

    self.validator.validate data, self.new_constraint extra_fields_message: "my_message", fields: {
      "foo" => constraint,
    }

    self
      .build_violation("my_message", CONSTRAINT::NO_SUCH_FIELD_ERROR)
      .invalid_value(6)
      .add_parameter("{{ field }}", "baz")
      .at_path("property.path[baz]")
      .assert_violation
  end

  def test_extra_fields_disallowed_with_optional_values : Nil
    constraint = AVD::Constraints::Optional.new

    data = self.prepare_test_data({
      "baz" => 6,
    })

    self.validator.validate data, self.new_constraint extra_fields_message: "my_message", fields: {
      "foo" => constraint,
    }

    self
      .build_violation("my_message", CONSTRAINT::NO_SUCH_FIELD_ERROR)
      .invalid_value(6)
      .add_parameter("{{ field }}", "baz")
      .at_path("property.path[baz]")
      .assert_violation
  end

  def test_nil_not_considered_extra_field : Nil
    constraint = AVD::Constraints::Range.new(4..)

    data = self.prepare_test_data({
      "foo" => nil,
    })

    self.expect_validate_value_at 0, "[foo]", data["foo"], [constraint]

    self.validator.validate data, self.new_constraint fields: {
      "foo" => constraint,
    }

    self.assert_no_violation
  end

  def test_extra_fields_allowed : Nil
    constraint = AVD::Constraints::Range.new(4..)

    data = self.prepare_test_data({
      "foo" => 5,
      "baz" => 6,
    })

    self.expect_validate_value_at 0, "[foo]", data["foo"], [constraint]

    self.validator.validate data, self.new_constraint allow_extra_fields: true, fields: {
      "foo" => constraint,
    }

    self.assert_no_violation
  end

  def test_missing_fields_disallowed : Nil
    constraint = AVD::Constraints::Range.new(4..)

    data = self.prepare_test_data({} of String => Int32)

    self.validator.validate data, self.new_constraint missing_fields_message: "my_message", fields: {
      "foo" => constraint,
    }

    self
      .build_violation("my_message", CONSTRAINT::MISSING_FIELD_ERROR)
      .at_path("property.path[foo]")
      .add_parameter("{{ field }}", "foo")
      .invalid_value(nil)
      .assert_violation
  end

  def test_missing_fields_allowed : Nil
    constraint = AVD::Constraints::Range.new(4..)

    data = self.prepare_test_data({} of String => Int32)

    self.validator.validate data, self.new_constraint allow_missing_fields: true, fields: {
      "foo" => constraint,
    }

    self.assert_no_violation
  end

  def test_optional_field_present_null : Nil
    data = self.prepare_test_data({
      "foo" => nil,
    })

    self.validator.validate data, self.new_constraint fields: {
      "foo" => AVD::Constraints::Optional.new,
    }

    self.assert_no_violation
  end

  def test_optional_field_not_present : Nil
    data = self.prepare_test_data({} of String => Int32)

    self.validator.validate data, self.new_constraint fields: {
      "foo" => AVD::Constraints::Optional.new,
    }

    self.assert_no_violation
  end

  def test_optional_field_single_constraint : Nil
    data = {
      "foo" => 5,
    }

    constraint = AVD::Constraints::Range.new(4..)

    self.expect_validate_value_at 0, "[foo]", data["foo"], [constraint]

    data = self.prepare_test_data data

    self.validator.validate data, self.new_constraint fields: {
      "foo" => AVD::Constraints::Optional.new constraint,
    }

    self.assert_no_violation
  end

  def test_optional_field_multiple_constraints : Nil
    data = {
      "foo" => 5,
    }

    constraints = [
      AVD::Constraints::NotNil.new,
      AVD::Constraints::Range.new(4..),
    ]

    self.expect_validate_value_at 0, "[foo]", data["foo"], constraints

    data = self.prepare_test_data data

    self.validator.validate data, self.new_constraint fields: {
      "foo" => AVD::Constraints::Optional.new constraints,
    }

    self.assert_no_violation
  end

  def test_required_field_present_null : Nil
    data = self.prepare_test_data({
      "foo" => nil,
    })

    self.validator.validate data, self.new_constraint fields: {
      "foo" => AVD::Constraints::Required.new,
    }

    self.assert_no_violation
  end

  def test_required_field_not_present : Nil
    data = self.prepare_test_data({} of String => Int32)

    self.validator.validate data, self.new_constraint missing_fields_message: "my_message", fields: {
      "foo" => AVD::Constraints::Required.new,
    }

    self
      .build_violation("my_message", CONSTRAINT::MISSING_FIELD_ERROR)
      .at_path("property.path[foo]")
      .add_parameter("{{ field }}", "foo")
      .invalid_value(nil)
      .assert_violation
  end

  def test_required_field_single_constraint : Nil
    data = {
      "foo" => 5,
    }

    constraint = AVD::Constraints::Range.new(4..)

    self.expect_validate_value_at 0, "[foo]", data["foo"], [constraint]

    data = self.prepare_test_data data

    self.validator.validate data, self.new_constraint fields: {
      "foo" => AVD::Constraints::Required.new constraint,
    }

    self.assert_no_violation
  end

  def test_required_field_multiple_constraints : Nil
    data = {
      "foo" => 5,
    }

    constraints = [
      AVD::Constraints::NotNil.new,
      AVD::Constraints::Range.new(4..),
    ]

    self.expect_validate_value_at 0, "[foo]", data["foo"], constraints

    data = self.prepare_test_data data

    self.validator.validate data, self.new_constraint fields: {
      "foo" => AVD::Constraints::Required.new constraints,
    }

    self.assert_no_violation
  end

  def test_does_not_mutate_object : Nil
    hash = {
      "foo" => 3,
    }

    constraint = AVD::Constraints::Range.new(2..)

    self.expect_validate_value_at 0, "[foo]", hash["foo"], [constraint]

    data = self.prepare_test_data hash

    self.validator.validate data, self.new_constraint fields: {
      "foo" => constraint,
    }

    hash.should eq({"foo" => 3})
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
