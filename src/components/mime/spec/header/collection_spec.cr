require "../spec_helper"

struct HeaderCollectionTest < ASPEC::TestCase
  def test_line_length : Nil
    headers = AMIME::Header::Collection.new
    headers.add_date_header "date", Time.utc

    headers.line_length.should eq 76
    headers["date"].max_line_length.should eq 76

    headers.line_length = 50

    headers.line_length.should eq 50
    headers["date"].max_line_length.should eq 50
  end

  def test_add_mailbox_list_header : Nil
    headers = AMIME::Header::Collection.new
    headers.add_mailbox_list_header "from", ["me@example.com"]
    headers["from"].should_not be_nil
  end

  def test_add_date_header : Nil
    headers = AMIME::Header::Collection.new
    headers.add_date_header "date", Time.utc
    headers["date"].should_not be_nil
  end

  def test_add_text_header : Nil
    headers = AMIME::Header::Collection.new
    headers.add_text_header "subject", "The Subject"
    headers["subject"].should_not be_nil
  end

  def test_add_parameterized_header : Nil
    headers = AMIME::Header::Collection.new
    headers.add_parameterized_header "content-type", "text/plain", {"charset" => "UTF-8"}
    headers["content-type"].should_not be_nil
  end

  def test_add_id_header : Nil
    headers = AMIME::Header::Collection.new
    headers.add_id_header "message-id", "some@id"
    headers["message-id"].should_not be_nil
  end

  def test_add_path_header : Nil
    headers = AMIME::Header::Collection.new
    headers.add_path_header "return-path", "me@example.com"
    headers["return-path"].should_not be_nil
  end

  def test_has_key : Nil
    headers = AMIME::Header::Collection.new
    headers.has_key?("date").should be_false
    headers.add_date_header "date", Time.utc
    headers.has_key?("date").should be_true
  end

  def test_is_unique_header : Nil
    AMIME::Header::Collection.unique_header?("date").should be_true
    AMIME::Header::Collection.unique_header?("foo").should be_false
  end

  @[TestWith(
    {AMIME::Header::Date.new("date", Time.utc)},
    {AMIME::Header::MailboxList.new("from", [AMIME::Address.new "me@example.com"])},
    {AMIME::Header::MailboxList.new("to", [AMIME::Address.new "me@example.com"])},
    {AMIME::Header::MailboxList.new("cc", [AMIME::Address.new "me@example.com"])},
    {AMIME::Header::MailboxList.new("bcc", [AMIME::Address.new "me@example.com"])},
    {AMIME::Header::MailboxList.new("reply-to", [AMIME::Address.new "me@example.com"])},
    {AMIME::Header::Path.new("return-path", AMIME::Address.new "me@example.com")},
    {AMIME::Header::Mailbox.new("sender", AMIME::Address.new "me@example.com")},
    {AMIME::Header::Identification.new("message-id", "some@id")},
    {AMIME::Header::Identification.new("in-reply-to", "some@id")},
    {AMIME::Header::Identification.new("references", "some@id")},
    {AMIME::Header::Unstructured.new("in-reply-to", "some@id")},
    {AMIME::Header::Unstructured.new("references", "some@id")},
    {AMIME::Header::Unstructured.new("x-foo", "bar")}, # Handles custom headers
  )]
  def test_check_header_class_valid(header : AMIME::Header::Interface) : Nil
    AMIME::Header::Collection.check_header_class header
  end

  def test_check_header_class_invalid : Nil
    expect_raises AMIME::Exception::Logic, "The 'date' header must be an instance of 'Athena::MIME::Header::Date' (got 'Athena::MIME::Header::Unstructured')." do
      AMIME::Header::Collection.check_header_class AMIME::Header::Unstructured.new "date", "blah"
    end
  end

  def test_to_a : Nil
    headers = AMIME::Header::Collection.new
    headers.add_text_header "foo", "bar"
    headers.add_text_header "", ""

    headers.to_a.should eq ["foo: bar"]
  end

  def test_names : Nil
    headers = AMIME::Header::Collection.new
    headers.add_text_header "foo", "bar"
    headers.add_text_header "biz", "baz"

    headers.names.should eq ["foo", "biz"]
  end

  def test_all_no_args : Nil
    headers = AMIME::Header::Collection.new
    headers.add_text_header "foo", "bar"
    headers.add_text_header "biz", "baz"

    names = [] of String

    headers.all do |header|
      names << header.name
    end

    names.should eq ["foo", "biz"]
  end

  def test_all_specific_name : Nil
    headers = AMIME::Header::Collection.new
    headers.add_text_header "text", "bar"
    headers.add_text_header "text", "baz"

    values = [] of String

    headers.all "text" do |header|
      values << header.body.to_s
    end

    values.should eq ["bar", "baz"]
  end

  def test_untyped : Nil
    headers = AMIME::Header::Collection.new
    headers.add_date_header "date", Time.utc
    headers["DATE"].should_not be_nil
  end

  def test_untyped_multiple : Nil
    headers = AMIME::Header::Collection.new
    text1 = AMIME::Header::Unstructured.new "text", "1"
    text2 = AMIME::Header::Unstructured.new "text", "2"

    headers << text1
    headers << text2

    headers["text"].should be text1
  end

  def test_untyped_missing_name : Nil
    headers = AMIME::Header::Collection.new

    expect_raises AMIME::Exception::HeaderNotFound, "No headers with the name 'foo' exist." do
      headers["foo"]
    end
  end

  def test_typed_missing_name : Nil
    headers = AMIME::Header::Collection.new

    expect_raises AMIME::Exception::HeaderNotFound, "No headers with the name 'foo' exist." do
      headers["foo", AMIME::Header::Date]
    end
  end

  def test_nilable_untyped : Nil
    headers = AMIME::Header::Collection.new
    headers.add_date_header "date", Time.utc
    headers["DATE"]?.should_not be_nil
  end

  def test_nilable_untyped_multiple : Nil
    headers = AMIME::Header::Collection.new
    text1 = AMIME::Header::Unstructured.new "text", "1"
    text2 = AMIME::Header::Unstructured.new "text", "2"

    headers << text1
    headers << text2

    headers["text"]?.should be text1
  end

  def test_nilable_untyped_missing_name : Nil
    headers = AMIME::Header::Collection.new
    headers["foo"]?.should be_nil
  end

  def test_nilable_typed_missing_name : Nil
    headers = AMIME::Header::Collection.new
    headers["foo", AMIME::Header::Date]?.should be_nil
  end

  def test_set_unique_header : Nil
    headers = AMIME::Header::Collection.new
    headers.add_date_header "date", Time.utc

    expect_raises AMIME::Exception::Logic, "Cannot set header 'date' as it is already defined and must be unique." do
      headers.add_date_header "date", Time.utc
    end
  end

  def test_header_parameter : Nil
    headers = AMIME::Header::Collection.new
    headers.add_parameterized_header "content-type", "text/plain", {"charset" => "UTF-8"}

    headers.header_parameter("content-type", "charset").should eq "UTF-8"
  end

  def test_header_parameter_non_parameterized_header : Nil
    headers = AMIME::Header::Collection.new
    headers.add_text_header "foo", "bar"

    expect_raises AMIME::Exception::Logic, "Unable to get parameter 'param' on header 'foo' as the header is not of class 'Athena::MIME::Header::Parameterized'." do
      headers.header_parameter "foo", "param"
    end
  end

  def test_set_header_parameter_non_parameterized_header : Nil
    headers = AMIME::Header::Collection.new
    headers.add_text_header "foo", "bar"

    expect_raises AMIME::Exception::Logic, "Unable to set parameter 'param' on header 'foo' as the header is not of class 'Athena::MIME::Header::Parameterized'." do
      headers.header_parameter "foo", "param", "value"
    end
  end
end
