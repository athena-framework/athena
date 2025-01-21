require "../../spec_helper"

struct RelatedPartTest < ASPEC::TestCase
  def test_constructor : Nil
    part = AMIME::Part::Multipart::Related.new(
      a = AMIME::Part::Text.new("text content"),
      {
        b = AMIME::Part::Text.new("html content", sub_type: "html"),
        c = AMIME::Part::Text.new("html content again", sub_type: "html"),
      }
    )

    part.media_type.should eq "multipart"
    part.media_sub_type.should eq "related"
    part.parts.should eq [a, b, c]
    a.headers.has_key?("content-id").should be_false
    b.headers.has_key?("content-id").should be_true
    c.headers.has_key?("content-id").should be_true
  end

  def test_body_to_s
    body = AMIME::Part::Multipart::Related
      .new(
        AMIME::Part::Multipart::Alternative.new(
          AMIME::Part::Text.new("text content"),
          AMIME::Part::Text.new("html content", sub_type: "html")
        ),
        [] of AMIME::Part::Abstract
      )
      .body_to_s

    body.should contain "text content"
    body.should contain "html content"
  end
end
