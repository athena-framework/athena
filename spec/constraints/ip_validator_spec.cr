require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::IP

struct IPValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint
    self.assert_no_violation
  end

  def test_empty_string_is_valid : Nil
    self.validator.validate "", self.new_constraint
  end

  @[DataProvider("valid_v4s")]
  def test_valid_v4s(value : String) : Nil
    self.validator.validate value, self.new_constraint
    self.assert_no_violation
  end

  def valid_v4s : Tuple
    {
      {"0.0.0.0"},
      {"10.0.0.0"},
      {"123.45.67.178"},
      {"172.16.0.0"},
      {"192.168.1.0"},
      {"224.0.0.1"},
      {"255.255.255.255"},
      {"127.0.0.0"},
    }
  end

  @[DataProvider("valid_v6s")]
  def test_valid_v6s(value : String) : Nil
    self.validator.validate value, self.new_constraint version: CONSTRAINT::Version::V6
    self.assert_no_violation
  end

  def valid_v6s : Tuple
    {
      {"2001:0db8:85a3:0000:0000:8a2e:0370:7334"},
      {"2001:0DB8:85A3:0000:0000:8A2E:0370:7334"},
      {"2001:0Db8:85a3:0000:0000:8A2e:0370:7334"},
      {"fdfe:dcba:9876:ffff:fdc6:c46b:bb8f:7d4c"},
      {"fdc6:c46b:bb8f:7d4c:fdc6:c46b:bb8f:7d4c"},
      {"fdc6:c46b:bb8f:7d4c:0000:8a2e:0370:7334"},
      {"fe80:0000:0000:0000:0202:b3ff:fe1e:8329"},
      {"fe80:0:0:0:202:b3ff:fe1e:8329"},
      {"fe80::202:b3ff:fe1e:8329"},
      {"0:0:0:0:0:0:0:0"},
      {"::"},
      {"0::"},
      {"::0"},
      {"0::0"},
      {"2001:0db8:85a3:0000:0000:8a2e:0.0.0.0"}, # IPv4 mapped to IP
      {"::0.0.0.0"},
      {"::255.255.255.255"},
      {"::123.45.67.178"},
    }
  end

  @[DataProvider("valid_v4s_v6s")]
  def test_valid_v4s_v6s(value : String) : Nil
    self.validator.validate value, self.new_constraint version: CONSTRAINT::Version::V4_V6
    self.assert_no_violation
  end

  def valid_v4s_v6s : Tuple
    self.valid_v4s + self.valid_v6s
  end

  @[DataProvider("invalid_v4s")]
  def test_invalid_v4s(value : String) : Nil
    self.validator.validate value, self.new_constraint message: "my_message"
    self.assert_violation "my_message", CONSTRAINT::INVALID_IP_ERROR, value
  end

  def invalid_v4s : Tuple
    {
      {"0"},
      {"0.0"},
      {"0.0.0"},
      {"256.0.0.0"},
      {"0.256.0.0"},
      {"0.0.256.0"},
      {"0.0.0.256"},
      {"-1.0.0.0"},
      {"foobar"},
    }
  end

  @[DataProvider("invalid_v6s")]
  def test_invalid_v6s(value : String) : Nil
    self.validator.validate value, self.new_constraint message: "my_message", version: CONSTRAINT::Version::V6
    self.assert_violation "my_message", CONSTRAINT::INVALID_IP_ERROR, value
  end

  def invalid_v6s : Tuple
    {
      {"z001:0db8:85a3:0000:0000:8a2e:0370:7334"},
      {"fe80"},
      {"fe80:8329"},
      {"fe80:::202:b3ff:fe1e:8329"},
      {"fe80::202:b3ff::fe1e:8329"},
      {"2001:0db8:85a3:0000:0000:8a2e:0370:0.0.0.0"}, # IPv4 mapped to IPv6
      {"::0.0"},
      {"::0.0.0"},
      {"::256.0.0.0"},
      {"::0.256.0.0"},
      {"::0.0.256.0"},
      {"::0.0.0.256"},
    }
  end

  @[DataProvider("invalid_v4s_v6s")]
  def test_invalid_v4s_v6s(value : String) : Nil
    self.validator.validate value, self.new_constraint message: "my_message", version: CONSTRAINT::Version::V4_V6
    self.assert_violation "my_message", CONSTRAINT::INVALID_IP_ERROR, value
  end

  def invalid_v4s_v6s : Tuple
    self.invalid_v4s + self.invalid_v6s
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
