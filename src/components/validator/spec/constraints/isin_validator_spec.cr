require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::ISIN

struct ISINValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint
    self.assert_no_violation
  end

  def test_empty_string_is_valid : Nil
    self.validator.validate "", self.new_constraint
  end

  @[DataProvider("valid_isins")]
  def test_valid_isins(value : String) : Nil
    self.validator.validate value, self.new_constraint
    self.expect_violation_at 0, value, AVD::Constraints::Luhn.new
    self.assert_no_violation
  end

  def valid_isins : Tuple
    {
      {"XS2125535901"}, # Goldman Sachs International
      {"DE0005140008"}, # Deutsche Bankg AG
      {"CH0528261156"}, # Leonteq Securities AG [Guernsey]
      {"US0378331005"}, # Apple, Inc.
      {"AU0000XVGZA3"}, # TREASURY CORP VICTORIA 5 3/4% 2005-2016
      {"GB0002634946"}, # BAE Systems
      {"CH0528261099"}, # Leonteq Securities AG [Guernsey]
      {"XS2155672814"}, # OP Corporate Bank plc
      {"XS2155687259"}, # Orbian Financial Services III, LLC
      {"XS2155696672"}, # Sheffield Receivables Company LLC
    }
  end

  @[DataProvider("invalid_length_isins")]
  def test_invalid_length_isins(value : String) : Nil
    self.assert_violation value, CONSTRAINT::INVALID_LENGTH_ERROR
  end

  def invalid_length_isins : Tuple
    {
      {"X"},
      {"XS"},
      {"XS2"},
      {"XS21"},
      {"XS215"},
      {"XS2155"},
      {"XS21556"},
      {"XS215569"},
      {"XS2155696"},
      {"XS21556966"},
      {"XS215569667"},
    }
  end

  @[DataProvider("invalid_pattern_isins")]
  def test_invalid_pattern_isins(value : String) : Nil
    self.assert_violation value, CONSTRAINT::INVALID_PATTERN_ERROR
  end

  def invalid_pattern_isins : Tuple
    {
      {"X12155696679"},
      {"123456789101"},
      {"XS215569667E"},
      {"XS215E69667A"},
    }
  end

  @[DataProvider("invalid_checksum_isins")]
  def test_invalid_checksum_isins(value : String) : Nil
    self.expect_violation_at 0, value, AVD::Constraints::Luhn.new
    self.assert_violation value, CONSTRAINT::INVALID_CHECKSUM_ERROR
  end

  def invalid_checksum_isins : Tuple
    {
      {"XS2112212144"},
      {"DE013228VA77"},
      {"CH0512361156"},
      {"XS2125660123"},
      {"XS2012587408"},
      {"XS2012380102"},
      {"XS2012239364"},
    }
  end

  private def assert_violation(isin : String, code : String) : Nil
    self.validator.validate isin, self.new_constraint message: "my_message"
    self.assert_violation "my_message", code, isin
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
