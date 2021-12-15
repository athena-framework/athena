require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::URL

private class EmptyURLObject
  def to_s(io : IO) : Nil
    io << ""
  end
end

struct URLValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  def test_nil_is_valid : Nil
    self.validator.validate nil, self.new_constraint
    self.assert_no_violation
  end

  def test_empty_string_is_valid : Nil
    self.validator.validate "", self.new_constraint
  end

  def test_empty_string_from_object_is_valid : Nil
    self.validator.validate EmptyURLObject.new, self.new_constraint
    self.assert_no_violation
  end

  @[DataProvider("valid_urls")]
  def test_valid_urls(value : String) : Nil
    self.validator.validate value, self.new_constraint
    self.assert_no_violation
  end

  @[DataProvider("valid_urls")]
  @[DataProvider("valid_relative_urls")]
  def test_valid_relative_urls(value : String) : Nil
    self.validator.validate value, self.new_constraint relative_protocol: true
    self.assert_no_violation
  end

  def valid_urls : Tuple
    {
      {"http://a.pl"},
      {"http://www.example.com"},
      {"http://www.example.com."},
      {"http://www.example.museum"},
      {"https://example.com/"},
      {"https://example.com:80/"},
      {"http://examp_le.com"},
      {"http://www.sub_domain.examp_le.com"},
      {"http://www.example.coop/"},
      {"http://www.test-example.com/"},
      {"http://www.crystal-lang.org/"},
      {"http://crystal.fake/blog/"},
      {"http://crystal-lang.org/?"},
      {"http://crystal-lang.org/search?type=&q=url+validator"},
      {"http://crystal-lang.org/#"},
      {"http://crystal-lang.org/#?"},
      {"http://crystal-lang.org/reference/getting_started/http_server.html#http-server"},
      {"http://very.long.domain.name.com/"},
      {"http://localhost/"},
      {"http://myhost123/"},
      {"http://127.0.0.1/"},
      {"http://127.0.0.1:80/"},
      {"http://[::1]/"},
      {"http://[::1]:80/"},
      {"http://[1:2:3::4:5:6:7]/"},
      {"http://sãopaulo.com/"},
      {"http://xn--sopaulo-xwa.com/"},
      {"http://sãopaulo.com.br/"},
      {"http://xn--sopaulo-xwa.com.br/"},
      {"http://пример.испытание/"},
      {"http://xn--e1afmkfd.xn--80akhbyknj4f/"},
      {"http://مثال.إختبار/"},
      {"http://xn--mgbh0fb.xn--kgbechtv/"},
      {"http://例子.测试/"},
      {"http://xn--fsqu00a.xn--0zwm56d/"},
      {"http://例子.測試/"},
      {"http://xn--fsqu00a.xn--g6w251d/"},
      {"http://例え.テスト/"},
      {"http://xn--r8jz45g.xn--zckzah/"},
      {"http://مثال.آزمایشی/"},
      {"http://xn--mgbh0fb.xn--hgbk6aj7f53bba/"},
      {"http://실례.테스트/"},
      {"http://xn--9n2bp8q.xn--9t4b11yi5a/"},
      {"http://العربية.idn.icann.org/"},
      {"http://xn--ogb.idn.icann.org/"},
      {"http://xn--e1afmkfd.xn--80akhbyknj4f.xn--e1afmkfd/"},
      {"http://xn--espaa-rta.xn--ca-ol-fsay5a/"},
      {"http://xn--d1abbgf6aiiy.xn--p1ai/"},
      {"http://☎.com/"},
      {"http://username:password@crystal-lang.org"},
      {"http://user.name:password@crystal-lang.org"},
      {"http://user_name:pass_word@crystal-lang.org"},
      {"http://username:pass.word@crystal-lang.org"},
      {"http://user.name:pass.word@crystal-lang.org"},
      {"http://user-name@crystal-lang.org"},
      {"http://user_name@crystal-lang.org"},
      {"http://u%24er:password@crystal-lang.org"},
      {"http://user:pa%24%24word@crystal-lang.org"},
      {"http://crystal-lang.org?"},
      {"http://crystal-lang.org?query=1"},
      {"http://crystal-lang.org/?query=1"},
      {"http://crystal-lang.org#"},
      {"http://crystal-lang.org#fragment"},
      {"http://crystal-lang.org/#fragment"},
      {"http://crystal-lang.org/#one_more%20test"},
      {"http://example.com/exploit.html?hello[0]=test"},
    }
  end

  def valid_relative_urls : Tuple
    {
      {"//example.com"},
      {"//examp_le.com"},
      {"//example.fake/blog/"},
      {"//example.com/search?type=&q=url+validator"},
    }
  end

  @[DataProvider("invalid_urls")]
  def test_invalid_urls(value : String) : Nil
    self.validator.validate value, self.new_constraint message: "my_message"
    self.assert_violation "my_message", CONSTRAINT::INVALID_URL_ERROR, value
  end

  @[DataProvider("invalid_urls")]
  @[DataProvider("invalid_relative_urls")]
  def test_invalid_relative_urls(value : String) : Nil
    self.validator.validate value, self.new_constraint message: "my_message", relative_protocol: true
    self.assert_violation "my_message", CONSTRAINT::INVALID_URL_ERROR, value
  end

  def invalid_urls : Tuple
    {
      {"google.com"},
      {"://google.com"},
      {"http ://google.com"},
      {"http:/google.com"},
      {"http://google.com::aa"},
      {"http://google.com:aa"},
      {"ftp://google.fr"},
      {"faked://google.fr"},
      {"http://127.0.0.1:aa/"},
      {"ftp://[::1]/"},
      {"http://[::1"},
      {"http://hello.☎/"},
      {"http://:password@example.com"},
      {"http://:password@@example.com"},
      {"http://username:passwordexample.com"},
      {"http://usern@me:password@example.com"},
      {"http://nota%hex:password@example.com"},
      {"http://example.com/exploit.html?<script>alert(1);</script>"},
      {"http://example.com/exploit.html?hel lo"},
      {"http://example.com/exploit.html?not_a%hex"},
      {"http://"},
    }
  end

  def invalid_relative_urls : Tuple
    {
      {"/google.com"},
      {"//google.com::aa"},
      {"//google.com:aa"},
      {"//127.0.0.1:aa/"},
      {"//[::1"},
      {"//hello.☎/"},
      {"//:password@example.com"},
      {"//:password@@example.com"},
      {"//username:passwordexample.com"},
      {"//usern@me:password@example.com"},
      {"//example.com/exploit.html?<script>alert(1);</script>"},
      {"//example.com/exploit.html?hel lo"},
      {"//example.com/exploit.html?not_a%hex"},
      {"//"},
    }
  end

  @[DataProvider("valid_custom_urls")]
  def test_custom_protocols_are_valid(value : String) : Nil
    self.validator.validate value, self.new_constraint protocols: ["ftp", "file", "git"]
    self.assert_no_violation
  end

  def valid_custom_urls : Tuple
    {
      {"ftp://example.com"},
      {"file://127.0.0.1"},
      {"git://[::1]/"},
    }
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
