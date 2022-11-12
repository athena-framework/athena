require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::ISSN

struct ISSNValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint
    self.assert_no_violation
  end

  def test_empty_string_is_valid : Nil
    self.validator.validate "", self.new_constraint
  end

  @[DataProvider("valid_lowercase_issns")]
  def test_case_sensitive_issns(value : String) : Nil
    self.validator.validate value, self.new_constraint message: "my_message", case_sensitive: true
    self.assert_violation "my_message", CONSTRAINT::INVALID_CASE_ERROR, value
  end

  def valid_lowercase_issns : Tuple
    {
      {"2162-321x"},
      {"2160-200x"},
      {"1537-453x"},
      {"1937-710x"},
      {"0002-922x"},
      {"1553-345x"},
      {"1553-619x"},
    }
  end

  @[DataProvider("valid_non_hyphenated_issns")]
  def test_hyphen_required_issns(value : String) : Nil
    self.validator.validate value, self.new_constraint message: "my_message", require_hyphen: true
    self.assert_violation "my_message", CONSTRAINT::MISSING_HYPHEN_ERROR, value
  end

  def valid_non_hyphenated_issns : Tuple
    {
      {"2162321X"},
      {"01896016"},
      {"15744647"},
      {"14350645"},
      {"07174055"},
      {"20905076"},
      {"14401592"},
    }
  end

  def valid_full_issns : Tuple
    {
      {"1550-7416"},
      {"1539-8560"},
      {"2156-5376"},
      {"1119-023X"},
      {"1684-5315"},
      {"1996-0786"},
      {"1684-5374"},
      {"1996-0794"},
    }
  end

  @[DataProvider("valid_issns")]
  def test_valid_issns(value : String) : Nil
    self.validator.validate value, self.new_constraint
    self.assert_no_violation
  end

  def valid_issns : Tuple
    self.valid_lowercase_issns + self.valid_non_hyphenated_issns + self.valid_full_issns
  end

  def invalid_issns : Tuple
    {
      {0, CONSTRAINT::TOO_SHORT_ERROR},
      {"1539", CONSTRAINT::TOO_SHORT_ERROR},
      {"2156-537A", CONSTRAINT::INVALID_CHARACTERS_ERROR},
      {"1119-0231", CONSTRAINT::CHECKSUM_FAILED_ERROR},
      {"1684-5312", CONSTRAINT::CHECKSUM_FAILED_ERROR},
      {"1996-0783", CONSTRAINT::CHECKSUM_FAILED_ERROR},
      {"1684-537X", CONSTRAINT::CHECKSUM_FAILED_ERROR},
      {"1996-0795", CONSTRAINT::CHECKSUM_FAILED_ERROR},
    }
  end

  @[DataProvider("invalid_issns")]
  def test_invalid_issns(value : String | Number, code : String) : Nil
    self.validator.validate value, self.new_constraint message: "my_message"
    self.assert_violation "my_message", code, value
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    AVD::Constraints::ISSN::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
