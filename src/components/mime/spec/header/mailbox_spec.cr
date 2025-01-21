require "../spec_helper"

struct MailboxHeaderTest < ASPEC::TestCase
  def test_happy_path : Nil
    header = AMIME::Header::Mailbox.new "sender", address = AMIME::Address.new "me@example.com"
    header.body.should eq address

    other_address = AMIME::Address.new "you@example.com"
    header.body = other_address
    header.body.should eq other_address
  end

  def test_body_to_s_no_name : Nil
    header = AMIME::Header::Mailbox.new("sender", AMIME::Address.new "me@example.com")
    header.body_to_s.should eq "me@example.com"

    header.body = AMIME::Address.new "me@fußball.com"
    header.body_to_s.should eq "me@xn--fuball-cta.com"
  end

  def test_body_to_s_with_name : Nil
    AMIME::Header::Mailbox
      .new("sender", AMIME::Address.new "me@example.com", "Jon Sno")
      .body_to_s
      .should eq "Jon Sno <me@example.com>"
  end

  def test_body_to_s_with_quoted_name : Nil
    AMIME::Header::Mailbox
      .new("sender", AMIME::Address.new "me@example.com", %(Jon Sno, "with love"))
      .body_to_s
      .should eq %("Jon Sno, \\"with love\\"" <me@example.com>)
  end

  def test_body_to_s_with_escaped : Nil
    AMIME::Header::Mailbox
      .new("sender", AMIME::Address.new "me@example.com", %(Jon Sno, \\escaped\\))
      .body_to_s
      .should eq %("Jon Sno, \\\\escaped\\\\" <me@example.com>)
  end

  def test_body_to_s_with_encoded_byte : Nil
    header = AMIME::Header::Mailbox.new("sender", AMIME::Address.new "me@example.com", %(Jon S\x8F o))
    header.charset = "iso-8859-1"
    header.body_to_s.should eq %(Jon =?iso-8859-1?Q?S=8F?= o <me@example.com>)
  end

  def test_utf8_chars_in_local_part : Nil
    AMIME::Header::Mailbox
      .new("sender", AMIME::Address.new "fußball@example.com")
      .body_to_s
      .should eq "fußball@example.com"
  end

  def test_utf8_chars_in_local_part_name_with_space : Nil
    AMIME::Header::Mailbox
      .new("sender", AMIME::Address.new "fußball@example.com", "fußball fußball")
      .body_to_s
      .should eq "=?UTF-8?Q?fu=C3=9Fball_fu=C3=9Fball?= <fußball@example.com>"
  end

  def test_utf8_chars_in_local_part_name_with_double_space : Nil
    AMIME::Header::Mailbox
      .new("sender", AMIME::Address.new "fußball@example.com", "fußball  fußball")
      .body_to_s
      .should eq "=?UTF-8?Q?fu=C3=9Fball?=  =?UTF-8?Q?fu=C3=9Fball?= <fußball@example.com>"
  end

  def test_to_s_address_only : Nil
    AMIME::Header::Mailbox
      .new("sender", AMIME::Address.new "me@example.com")
      .to_s
      .should eq "sender: me@example.com"
  end

  def test_to_s_address_name : Nil
    AMIME::Header::Mailbox
      .new("sender", AMIME::Address.new "me@example.com", "Jon Sno")
      .to_s
      .should eq "sender: Jon Sno <me@example.com>"
  end
end
