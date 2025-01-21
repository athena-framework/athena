require "../spec_helper"

struct MessagePartTest < ASPEC::TestCase
  def test_constructor : Nil
    part = AMIME::Part::Message.new AMIME::Email.new.from("me@example.com").to("you@example.com").text("text content")
    part.body.should contain "text content"
    part.body_to_s.should contain "text content"
    part.media_type.should eq "message"
    part.media_sub_type.should eq "rfc822"
  end

  def test_headers : Nil
    AMIME::Part::Message
      .new(AMIME::Email.new.from("me@example.com").text("text content").subject("subject"))
      .prepared_headers
      .should eq AMIME::Header::Collection.new(
        AMIME::Header::Parameterized.new("content-type", "message/rfc822", {"name" => "subject.eml"}),
        AMIME::Header::Unstructured.new("content-transfer-encoding", "base64"),
        AMIME::Header::Parameterized.new("content-disposition", "attachment", {"name" => "subject.eml", "filename" => "subject.eml"}),
      )
  end
end
