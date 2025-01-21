require "../spec_helper"

struct PathHeaderTest < ASPEC::TestCase
  def test_happy_path : Nil
    header = AMIME::Header::Path.new "return-path", address = AMIME::Address.new "me@example.com"
    header.body.should eq address

    address = AMIME::Address.new "you@example.com"
    header.body = address
    header.body.should eq address
  end

  # def test_raises_if_invalid_address : Nile
  # end

  def test_body_to_s : Nil
    AMIME::Header::Path
      .new("return-path", AMIME::Address.new "me@example.com")
      .body_to_s.should eq "<me@example.com>"
  end

  def test_body_to_s_utf8_chars_in_local_part : Nil
    AMIME::Header::Path
      .new("return-path", AMIME::Address.new "chrïs@example.com")
      .body_to_s.should eq "<chrïs@example.com>"
  end

  def test_body_to_s_idn_encoded_if_needed : Nil
    AMIME::Header::Path
      .new("return-path", AMIME::Address.new "test@fußball.test")
      .body_to_s.should eq "<test@xn--fuball-cta.test>"
  end

  def test_to_s : Nil
    AMIME::Header::Path
      .new("return-path", AMIME::Address.new "me@example.com")
      .to_s.should eq "return-path: <me@example.com>"
  end
end
