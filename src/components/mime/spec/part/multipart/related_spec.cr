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
end
