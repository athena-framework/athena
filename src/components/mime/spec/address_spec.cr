require "./spec_helper"

struct AddressTest < ASPEC::TestCase
  def test_address_only : Nil
    a = AMIME::Address.new "contact@athenï.org"
    a.address.should eq "contact@athenï.org"
    a.to_s.should eq "contact@xn--athen-gta.org"
    a.encoded_address.should eq "contact@xn--athen-gta.org"
  end

  def test_address_and_name : Nil
    a = AMIME::Address.new "contact@athenï.org", "George"
    a.address.should eq "contact@athenï.org"
    a.name.should eq "George"
    a.to_s.should eq %("George" <contact@xn--athen-gta.org>)
    a.encoded_address.should eq "contact@xn--athen-gta.org"
  end

  def test_create : Nil
    a = AMIME::Address.new "contact@athenaframework.org"
    b = AMIME::Address.new "george@athenaframework.org", "George"

    AMIME::Address.create(a).should eq a
    AMIME::Address.create(b).should eq b
  end

  def test_create_invalid : Nil
    expect_raises AMIME::Exception::InvalidArgument, "Could not parse '<george@athenaframework' to a 'Athena::MIME::Address' instance." do
      AMIME::Address.create "<george@athenaframework"
    end
  end

  def test_create_multiple : Nil
    foo = AMIME::Address.new "foo@example.com"
    bar = AMIME::Address.new "bar@example.com"
    baz = AMIME::Address.new "baz@example.com"

    AMIME::Address.create_multiple("foo@example.com", "bar@example.com", baz).should eq [foo, bar, baz]
  end

  def test_unicode_local_part : Nil
    # dømi means example and is reserved by the .fo registry
    AMIME::Address.new("info@dømi.fo").has_unicode_local_part?.should be_false
    AMIME::Address.new("dømi@dømi.fo").has_unicode_local_part?.should be_true
  end

  @[TestWith(
    {"example@example.com", "", "example@example.com"},
    {"<example@example.com>", "", "example@example.com"},
    {"Jane Doe <example@example.com>", "Jane Doe", "example@example.com"},
    {"Jane Doe<example@example.com>", "Jane Doe", "example@example.com"},
    {"'Jane Doe' <example@example.com>", "Jane Doe", "example@example.com"},
    {"\"Jane Doe\" <example@example.com>", "Jane Doe", "example@example.com"},
    {"Jane Doe <\"ex<ample\"@example.com>", "Jane Doe", "\"ex<ample\"@example.com"},
    {"Jane Doe <\"ex<amp>le\"@example.com>", "Jane Doe", "\"ex<amp>le\"@example.com"},
    {"Jane Doe > <\"ex<am  p>le\"@example.com>", "Jane Doe >", "\"ex<am  p>le\"@example.com"},
    {"Jane Doe <example@example.com>discarded", "Jane Doe", "example@example.com"},
  )]
  def test_create_from_string(string : String, display_name : String, addr_spec : String) : Nil
    address = AMIME::Address.create string
    address.address.should eq addr_spec
    address.name.should eq display_name

    from_string_address = AMIME::Address.create address.to_s
    from_string_address.address.should eq addr_spec
    from_string_address.name.should eq display_name
  end

  @[TestWith(
    {""},
    {" "},
    {" \r\n "},
  )]
  def test_empty_name(name : String) : Nil
    mail = "mail@example.com"

    AMIME::Address.new(mail, name).to_s.should eq mail
  end

  def test_encode_name_if_contains_commas : Nil
    AMIME::Address.new("foo@example.com", "Foo, \"Bar").to_s.should eq %("Foo, "Bar" <foo@example.com>)
  end
end
