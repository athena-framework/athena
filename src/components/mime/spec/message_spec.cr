require "./spec_helper"

struct MessageTest < ASPEC::TestCase
  def test_construct : Nil
    m = AMIME::Message.new
    m.body.should be_nil
    m.headers.should eq AMIME::Header::Collection.new

    m = AMIME::Message.new(
      headers = AMIME::Header::Collection.new.tap { |h| h.add_date_header("date", Time.utc) },
      body = AMIME::Part::Text.new("content"),
    )
    m.headers.should be headers
    m.body.should be body

    m = AMIME::Message.new
    m.body = body
    m.headers = headers

    m.headers.should be headers
    m.body.should be body
  end

  def test_raises_when_no_from : Nil
    expect_raises AMIME::Exception::Logic, "An email must have a 'from' or a 'sender' header." do
      AMIME::Message.new.prepared_headers
    end
  end

  def test_prepared_headers_clone_headers : Nil
    m = AMIME::Message.new
    m.headers.add_mailbox_list_header "from", ["me@example.com"]
    m.headers.should_not be m.prepared_headers
  end

  def test_prepared_headers_sets_required_headers : Nil
    m = AMIME::Message.new
    m.headers.add_mailbox_list_header "from", ["me@example.com"]
    m.headers.add_mailbox_list_header "bcc", ["spy@example.com"]

    headers = m.prepared_headers
    headers.has_key?("mime-version").should be_true
    headers.has_key?("message-id").should be_true
    headers.has_key?("date").should be_true
    headers.has_key?("bcc").should be_false
  end

  def test_prepared_headers : Nil
    m = AMIME::Message.new
    m.headers.add_mailbox_list_header "from", ["me@example.com"]
    m.headers.add_date_header "date", now = Time.utc

    headers = m.prepared_headers

    headers.headers.size.should eq 4
    headers["from"].should eq AMIME::Header::MailboxList.new "from", [AMIME::Address.new "me@example.com"]
    headers["mime-version"].should eq AMIME::Header::Unstructured.new "mime-version", "1.0"
    headers["date"].should eq AMIME::Header::Date.new "date", now
  end

  def test_prepared_headers_named_from : Nil
    m = AMIME::Message.new
    m.headers.add_mailbox_list_header "from", [AMIME::Address.new "me@example.com", "Me"]
    headers = m.prepared_headers
    headers["from"].should eq AMIME::Header::MailboxList.new "from", [AMIME::Address.new "me@example.com", "Me"]
  end

  def test_prepared_headers_has_sender_when_needed : Nil
    m = AMIME::Message.new
    m.headers.add_mailbox_list_header "from", ["me@example.com"]
    m.prepared_headers.has_key?("sender").should be_false

    m = AMIME::Message.new
    m.headers.add_mailbox_list_header "from", ["me@example.com", "other@example.com"]
    m.prepared_headers["sender", AMIME::Header::Mailbox].body.address.should eq "me@example.com"

    m = AMIME::Message.new
    m.headers.add_mailbox_list_header "from", ["me@example.com", "other@example.com"]
    m.headers.add_mailbox_header "sender", "other@example.com"
    m.prepared_headers["sender", AMIME::Header::Mailbox].body.address.should eq "other@example.com"
  end

  def test_generate_message_id_raises_no_addresses : Nil
    expect_raises AMIME::Exception::Logic, "A 'from' header must have at least one email address." do
      m = AMIME::Message.new
      m.headers.add_mailbox_list_header "from", [] of String
      m.generate_message_id
    end
  end

  def test_generate_message_id_raises_no_from_or_sender : Nil
    expect_raises AMIME::Exception::Logic, "An email must have a 'from' or 'sender' header." do
      AMIME::Message.new.generate_message_id
    end
  end

  def test_to_s_no_content : Nil
    m = AMIME::Message.new
    m.headers.add_mailbox_list_header "from", ["me@example.com"]
    m.headers.add_date_header "date", Time.utc(2025, 1, 1, 12, 30)
    m.headers.add_id_header "message-id", "MESSAGE_ID"

    m.to_s.should eq <<-TXT
    from: me@example.com\r
    date: Wed, 1 Jan 2025 12:30:00 +0000\r
    message-id: <MESSAGE_ID>\r
    mime-version: 1.0\r
    content-type: text/plain; charset=UTF-8\r
    content-transfer-encoding: quoted-printable\r
    \r

    TXT
  end

  def test_to_s_with_content : Nil
    m = AMIME::Message.new body: AMIME::Part::Text.new("text content")
    m.headers.add_mailbox_list_header "from", ["me@example.com"]
    m.headers.add_date_header "date", Time.utc(2025, 1, 1, 12, 30)
    m.headers.add_id_header "message-id", "MESSAGE_ID"

    m.to_s.should eq <<-TXT
    from: me@example.com\r
    date: Wed, 1 Jan 2025 12:30:00 +0000\r
    message-id: <MESSAGE_ID>\r
    mime-version: 1.0\r
    content-type: text/plain; charset=UTF-8\r
    content-transfer-encoding: quoted-printable\r
    \r
    text content
    TXT
  end

  def test_ensure_validity_valid : Nil
    m = AMIME::Message.new
    m.headers.add_mailbox_list_header "from", ["me@example.com"]
    m.headers.add_mailbox_list_header "to", ["you@example.com"]

    m.ensure_validity
  end

  @[TestWith(
    { {"from" => ["me@example.com"]}, AMIME::Exception::Logic, "An email must have a 'to', 'cc', or 'bcc' header." },
    { {"from" => ["me@example.com"], "cc" => [] of String}, AMIME::Exception::Logic, "An email must have a 'to', 'cc', or 'bcc' header." },
    { {"from" => ["me@example.com"], "bcc" => [] of String}, AMIME::Exception::Logic, "An email must have a 'to', 'cc', or 'bcc' header." },
    { {"to" => [] of String, "from" => ["me@example.com"]}, AMIME::Exception::Logic, "An email must have a 'to', 'cc', or 'bcc' header." },
    { {"to" => ["you@example.com"]}, AMIME::Exception::Logic, "An email must have a 'from' or a 'sender' header." },
    { {"to" => ["you@example.com"], "from" => [] of String}, AMIME::Exception::Logic, "An email must have a 'from' or a 'sender' header." },
  )]
  def test_ensure_validity(headers : Hash(String, Array(String)), exception_class : ::Exception.class, exception_message : String)
    m = AMIME::Message.new
    headers.each do |k, v|
      m.headers.add_mailbox_list_header k, v
    end

    expect_raises exception_class, exception_message do
      m.ensure_validity
    end
  end
end
