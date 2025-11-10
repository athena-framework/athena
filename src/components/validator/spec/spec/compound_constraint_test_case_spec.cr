require "../spec_helper"

private class DummyCompoundConstraint < AVD::Constraints::Compound
  def constraints : Type
    [
      AVD::Constraints::NotBlank.new,
      AVD::Constraints::Length.new(...3),
      AVD::Constraints::Regex.new(/[a-z]+/),
      AVD::Constraints::Regex.new(/[0-9]+/),
    ]
  end
end

struct CompoundConstraintTestCaseTest < AVD::Spec::CompoundConstraintTestCase(String)
  protected def create_compound : AVD::Constraints::Compound
    DummyCompoundConstraint.new
  end

  def test_assert_no_violation : Nil
    self.validate_value "ab1"

    self.assert_no_violation
    self.assert_violation_count 0
  end

  def test_assert_is_raised_by_component : Nil
    self.validate_value ""

    self.assert_violations_raised_by_compound AVD::Constraints::NotBlank.new
    self.assert_violation_count 1
  end

  def test_multiple_assert_are_raised_by_compound : Nil
    self.validate_value "1234"

    self.assert_violations_raised_by_compound(
      AVD::Constraints::Length.new(...3),
      AVD::Constraints::Regex.new(/[a-z]+/),
    )
    self.assert_violation_count 2
  end

  def test_no_assert_raised_but_expected : Nil
    self.validate_value "azert"

    expect_raises ::Spec::AssertionFailed, "Expected violation(s) for constraint(s) 'Athena::Validator::Constraints::Length, Athena::Validator::Constraints::Regex' to be raised by compound." do
      self.assert_violations_raised_by_compound(
        AVD::Constraints::Length.new(..5),
        AVD::Constraints::Regex.new(/^[A-Z]+$/),
      )
    end
  end

  def test_assert_raised_by_compound_is_not_exactly_the_same : Nil
    self.validate_value "123"

    expect_raises ::Spec::AssertionFailed, "Expected violation(s) for constraint(s) 'Athena::Validator::Constraints::Regex' to be raised by compound." do
      self.assert_violations_raised_by_compound(
        AVD::Constraints::Regex.new(/^[A-Z]+$/),
      )
    end
  end

  def test_assert_raised_by_compound_but_got_none : Nil
    self.validate_value "123"

    expect_raises ::Spec::AssertionFailed, "Expected at least one violation for constraint(s): 'Athena::Validator::Constraints::Length', got none." do
      self.assert_violations_raised_by_compound(
        AVD::Constraints::Length.new(..5),
      )
    end
  end
end
