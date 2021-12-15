require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::Email

private class EmtpyEmailObject
  def to_s(io : IO) : Nil
    io << ""
  end
end

struct EmailValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint
    self.assert_no_violation
  end

  def test_empty_string_is_valid : Nil
    self.validator.validate "", self.new_constraint
  end

  def test_empty_string_from_object_is_valid : Nil
    self.validator.validate EmtpyEmailObject.new, self.new_constraint
    self.assert_no_violation
  end

  @[DataProvider("valid_emails")]
  def test_valid_emails(value : String) : Nil
    self.validator.validate value, self.new_constraint
    self.assert_no_violation
  end

  def valid_emails : Tuple
    {
      {"blacksmoke16@dietrich.app"},
      {"example@example.co.uk"},
      {"fabien_potencier@example.fr"},
      {"example@example.co..uk"},
      {"{}~!@!@£$%%^&*().!@£$%^&*()"},
      {"example@example.co..uk"},
      {"example@-example.com"},
      {"example@#{"a"*64}.com"},
    }
  end

  @[DataProvider("valid_emails_html5")]
  def test_valid_emails_html5(value : String) : Nil
    self.validator.validate value, self.new_constraint mode: CONSTRAINT::Mode::HTML5
    self.assert_no_violation
  end

  def valid_emails_html5 : Tuple
    {
      {"blacksmoke16@dietrich.app"},
      {"example@example.co.uk"},
      {"blacksmoke_blacksmoke@example.fr"},
      {"{}~!@example.com"},
    }
  end

  @[DataProvider("invalid_emails")]
  def test_invalid_emails(value : String) : Nil
    self.validator.validate value, self.new_constraint message: "my_message"
    self.assert_violation "my_message", CONSTRAINT::INVALID_FORMAT_ERROR, value
  end

  def invalid_emails : Tuple
    {
      {"example"},
      {"example@"},
      {"example@localhost"},
      {"foo@example.com bar"},
    }
  end

  @[DataProvider("invalid_emails_html5")]
  def test_invalid_emails_html5(value : String) : Nil
    self.validator.validate value, self.new_constraint mode: CONSTRAINT::Mode::HTML5, message: "my_message"
    self.assert_violation "my_message", CONSTRAINT::INVALID_FORMAT_ERROR, value
  end

  def invalid_emails_html5 : Tuple
    {
      {"example"},
      {"example@"},
      {"example@localhost"},
      {"example@example.co..uk"},
      {"foo@example.com bar"},
      {"example@example."},
      {"example@.fr"},
      {"@example.com"},
      {"example@example.com;example@example.com"},
      {"example@."},
      {" example@example.com"},
      {"example@ "},
      {" example@example.com "},
      {" example @example .com "},
      {"example@-example.com"},
      {"example@#{"a"*64}.com"},
    }
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
