require "../spec_helper"

struct MailboxListHeaderTest < ASPEC::TestCase
  def test_mailbox_is_set_for_address : Nil
    AMIME::Header::MailboxList
      .new("from", [AMIME::Address.new "me@example.com"])
      .address_strings
      .should eq ["me@example.com"]
  end

  def test_mailbox_is_set_for_named_address : Nil
    AMIME::Header::MailboxList
      .new("from", [AMIME::Address.new "me@example.com", "Jon Sno"])
      .address_strings
      .should eq ["Jon Sno <me@example.com>"]
  end

  def test_body_to_s : Nil
    AMIME::Header::MailboxList
      .new("from", [AMIME::Address.new "me@example.com", "Jon Sno"])
      .body_to_s
      .should eq "Jon Sno <me@example.com>"
  end

  def test_body_to_s_multiple : Nil
    AMIME::Header::MailboxList
      .new("from", [AMIME::Address.new("me@example.com", "Jon Sno"), AMIME::Address.new("you@example.com", "Jon Smith")])
      .body_to_s
      .should eq "Jon Sno <me@example.com>, Jon Smith <you@example.com>"
  end

  def test_to_s_multiple : Nil
    AMIME::Header::MailboxList
      .new("from", [AMIME::Address.new("me@example.com", "Jon Sno"), AMIME::Address.new("you@example.com", "Jon Smith")])
      .to_s
      .should eq "from: Jon Sno <me@example.com>, Jon Smith <you@example.com>"
  end

  def test_addresses : Nil
    AMIME::Header::MailboxList
      .new("from", [AMIME::Address.new "me@example.com", %(Jon Sno, "with love")])
      .address_strings
      .should eq [%("Jon Sno, \\"with love\\"" <me@example.com>)]
  end

  def test_quotes_escaped_chars : Nil
    AMIME::Header::MailboxList
      .new("from", [AMIME::Address.new "me@example.com", %(Jon Sno, \\escaped\\)])
      .address_strings
      .should eq [%("Jon Sno, \\\\escaped\\\\" <me@example.com>)]
  end

  def test_quotes_paren : Nil
    AMIME::Header::MailboxList
      .new("from", [AMIME::Address.new "me@example.com", %(Jon (Sno))])
      .address_strings
      .should eq [%("Jon (Sno)" <me@example.com>)]
  end

  def test_utf8_in_domain : Nil
    AMIME::Header::MailboxList
      .new("from", [AMIME::Address.new "me@fußball.com"])
      .address_strings
      .should eq ["me@xn--fuball-cta.com"]
  end

  def test_utf8_in_local_part : Nil
    AMIME::Header::MailboxList
      .new("from", [AMIME::Address.new "fußball@example.com"])
      .address_strings
      .should eq ["fußball@example.com"]
  end

  def test_multiple_addresses : Nil
    AMIME::Header::MailboxList
      .new("from", [AMIME::Address.new("me@example.com"), AMIME::Address.new("you@example.com")])
      .address_strings
      .should eq ["me@example.com", "you@example.com"]
  end

  def test_encoded_non_ascii : Nil
    header = AMIME::Header::MailboxList.new("sender", [AMIME::Address.new "me@example.com", %(Jon S\x8F o)])
    header.charset = "iso-8859-1"
    header.address_strings.should eq [%(Jon =?iso-8859-1?Q?S=8F?= o <me@example.com>)]
  end

  def test_body : Nil
    header = AMIME::Header::MailboxList.new("from", [AMIME::Address.new "me@example.com", "Jon Sno"])
    header.body = addresses = [AMIME::Address.new "you@example.com", "Jon Smith"]
    header.body.should eq addresses
  end
end
