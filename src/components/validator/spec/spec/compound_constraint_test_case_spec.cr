require "../spec_helper"

private class DummyCompoundConstraint < AVD::Constraints::Compound
  def constraints : Type
    [
      AVD::Constraints::NotBlank.new,
      AVD::Constraints::Size.new(..3),
      AVD::Constraints::Regex.new(/[a-z]+/),
      AVD::Constraints::Regex.new(/[0-9]+/),
    ]
  end
end

@[ASPEC::TestCase::Focus]
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
    self.validate_value "ab1"

    self.assert_violations_raised_by_compound AVD::Constraints::NotBlank.new
    self.assert_violation_count 1
  end
end
