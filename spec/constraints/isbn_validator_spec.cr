require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::ISBN

struct ISBNValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint
    self.assert_no_violation
  end

  def test_empty_string_is_valid : Nil
    self.validator.validate "", self.new_constraint
  end

  def test_message_is_used_if_set : Nil
    self.validator.validate "asdf", self.new_constraint message: "my_message"
    self.assert_violation "my_message", CONSTRAINT::INVALID_CHARACTERS_ERROR, "asdf"
  end

  @[DataProvider("valid_isbn10s")]
  def test_valid_isbn10s(value : String) : Nil
    self.validator.validate value, self.new_constraint type: CONSTRAINT::Type::ISBN10
    self.assert_no_violation
  end

  def valid_isbn10s : Tuple
    {
      {"2723442284"},
      {"2723442276"},
      {"2723455041"},
      {"2070546810"},
      {"2711858839"},
      {"2756406767"},
      {"2870971648"},
      {"226623854X"},
      {"2851806424"},
      {"0321812700"},
      {"0-45122-5244"},
      {"0-4712-92311"},
      {"0-9752298-0-X"},
    }
  end

  @[DataProvider("valid_isbn13s")]
  def test_valid_isbn10s(value : String) : Nil
    self.validator.validate value, self.new_constraint type: CONSTRAINT::Type::ISBN13
    self.assert_no_violation
  end

  def valid_isbn13s : Tuple
    {
      {"978-2723442282"},
      {"978-2723442275"},
      {"978-2723455046"},
      {"978-2070546817"},
      {"978-2711858835"},
      {"978-2756406763"},
      {"978-2870971642"},
      {"978-2266238540"},
      {"978-2851806420"},
      {"978-0321812704"},
      {"978-0451225245"},
      {"978-0471292319"},
    }
  end

  @[DataProvider("valid_isbns")]
  def test_valid_both(value : String) : Nil
    self.validator.validate value, self.new_constraint type: CONSTRAINT::Type::Both
    self.assert_no_violation
  end

  def valid_isbns : Tuple
    self.valid_isbn10s + self.valid_isbn13s
  end

  @[DataProvider("invalid_isbn10s")]
  def test_invalid_isbn10s(value : String, code : String) : Nil
    self.validator.validate value, self.new_constraint type: CONSTRAINT::Type::ISBN10, isbn10_message: "my_message"
    self.assert_violation "my_message", code, value
  end

  def invalid_isbn10s : Tuple
    {
      {"27234422841", CONSTRAINT::TOO_LONG_ERROR},
      {"272344228", CONSTRAINT::TOO_SHORT_ERROR},
      {"0-4712-9231", CONSTRAINT::TOO_SHORT_ERROR},
      {"1234567890", CONSTRAINT::CHECKSUM_FAILED_ERROR},
      {"0987656789", CONSTRAINT::CHECKSUM_FAILED_ERROR},
      {"7-35622-5444", CONSTRAINT::CHECKSUM_FAILED_ERROR},
      {"0-4X19-92611", CONSTRAINT::CHECKSUM_FAILED_ERROR},
      {"0_45122_5244", CONSTRAINT::INVALID_CHARACTERS_ERROR},
      {"2870#971#648", CONSTRAINT::INVALID_CHARACTERS_ERROR},
      {"0-9752298-0-x", CONSTRAINT::INVALID_CHARACTERS_ERROR},
      {"1A34567890", CONSTRAINT::INVALID_CHARACTERS_ERROR},
      {"2#{1.chr}70546810", CONSTRAINT::INVALID_CHARACTERS_ERROR},
    }
  end

  @[DataProvider("invalid_isbn13s")]
  def test_invalid_isbn13s(value : String, code : String) : Nil
    self.validator.validate value, self.new_constraint type: CONSTRAINT::Type::ISBN13, isbn13_message: "my_message"
    self.assert_violation "my_message", code, value
  end

  def invalid_isbn13s : Tuple
    {
      {"978-27234422821", CONSTRAINT::TOO_LONG_ERROR},
      {"978-272344228", CONSTRAINT::TOO_SHORT_ERROR},
      {"978-2723442-82", CONSTRAINT::TOO_SHORT_ERROR},
      {"978-2723442281", CONSTRAINT::CHECKSUM_FAILED_ERROR},
      {"978-0321513774", CONSTRAINT::CHECKSUM_FAILED_ERROR},
      {"979-0431225385", CONSTRAINT::CHECKSUM_FAILED_ERROR},
      {"980-0474292319", CONSTRAINT::CHECKSUM_FAILED_ERROR},
      {"0-4X19-92619812", CONSTRAINT::INVALID_CHARACTERS_ERROR},
      {"978_2723442282", CONSTRAINT::INVALID_CHARACTERS_ERROR},
      {"978#2723442282", CONSTRAINT::INVALID_CHARACTERS_ERROR},
      {"978-272C442282", CONSTRAINT::INVALID_CHARACTERS_ERROR},
      {"978-2#{1.chr}70546817", CONSTRAINT::INVALID_CHARACTERS_ERROR},
    }
  end

  @[DataProvider("invalid_isbn10s")]
  def test_invalid_both_isbn10s(value : String, code : String) : Nil
    self.validator.validate value, self.new_constraint type: CONSTRAINT::Type::Both, both_message: "my_message"

    # Too long for ISBN-10, but not long enough for ISBN-13
    if CONSTRAINT::TOO_LONG_ERROR == code
      code = CONSTRAINT::TYPE_NOT_RECOGNIZED_ERROR
    end

    self.assert_violation "my_message", code, value
  end

  @[DataProvider("invalid_isbn13s")]
  def test_invalid_both_isbn13s(value : String, code : String) : Nil
    self.validator.validate value, self.new_constraint type: CONSTRAINT::Type::Both, both_message: "my_message"

    # Too short for an ISBN-13, but not short enough for an ISBN-10
    if CONSTRAINT::TOO_SHORT_ERROR == code
      code = CONSTRAINT::TYPE_NOT_RECOGNIZED_ERROR
    end

    self.assert_violation "my_message", code, value
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
