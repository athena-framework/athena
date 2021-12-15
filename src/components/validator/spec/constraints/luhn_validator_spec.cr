require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::Luhn

struct LuhnValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint
    self.assert_no_violation
  end

  def test_empty_string_is_valid : Nil
    self.validator.validate "", self.new_constraint
  end

  @[DataProvider("valid_numbers")]
  def test_valid_numbers(value : String) : Nil
    self.validator.validate value, self.new_constraint
    self.assert_no_violation
  end

  def valid_numbers : Tuple
    {
      {"42424242424242424242"},
      {"378282246310005"},
      {"371449635398431"},
      {"378734493671000"},
      {"5610591081018250"},
      {"30569309025904"},
      {"38520000023237"},
      {"6011111111111117"},
      {"6011000990139424"},
      {"3530111333300000"},
      {"3566002020360505"},
      {"5555555555554444"},
      {"5105105105105100"},
      {"4111111111111111"},
      {"4012888888881881"},
      {"4222222222222"},
      {"5019717010103742"},
      {"6331101999990016"},
    }
  end

  @[DataProvider("invalid_numbers")]
  def test_invalid_numbers(value : String, code : String) : Nil
    self.validator.validate value, self.new_constraint message: "my_message"
    self.assert_violation "my_message", code, value
  end

  def invalid_numbers : Tuple
    {
      {"1234567812345678", CONSTRAINT::CHECKSUM_FAILED_ERROR},
      {"4222222222222222", CONSTRAINT::CHECKSUM_FAILED_ERROR},
      {"0000000000000000", CONSTRAINT::CHECKSUM_FAILED_ERROR},
      {"000000!000000000", CONSTRAINT::INVALID_CHARACTERS_ERROR},
      {"42-22222222222222", CONSTRAINT::INVALID_CHARACTERS_ERROR},
    }
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
