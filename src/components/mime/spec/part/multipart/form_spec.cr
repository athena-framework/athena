require "../../spec_helper"

struct FormPartTest < ASPEC::TestCase
  def test_constructor : Nil
    b = AMIME::Part::Text.new "content"
    c = AMIME::Part::Data.from_path "#{__DIR__}/../../fixtures/mimetypes/test.gif"
    part = AMIME::Part::Multipart::Form.new({
      "foo" => content = "very very long content that will not be cut even if the length is way more than 76 characters, ok?",
      "bar" => b.dup,
      "baz" => c.dup,
    })

    part.media_type.should eq "multipart"
    part.media_sub_type.should eq "form-data"

    t = AMIME::Part::Text.new content, encoding: "8bit"
    t.disposition = "form-data"
    t.name = "foo"
    t.headers.line_length = Int32::MAX

    b.disposition = "form-data"
    b.encoding = "8bit"
    b.name = "bar"
    b.headers.line_length = Int32::MAX

    c.disposition = "form-data"
    c.encoding = "8bit"
    c.name = "baz"
    c.headers.line_length = Int32::MAX

    part.parts.should eq [t, b, c]
  end

  def test_nested_array_parts : Nil
    p1 = AMIME::Part::Text.new "content", encoding: "8bit"

    part = AMIME::Part::Multipart::Form.new({
      "foo" => p1.dup,
      "bar" => {
        "baz" => {
          "0"   => p1.dup,
          "qux" => p1.dup,
        },
      },

      "2" => p1.dup,

      "quux" => [
        p1.dup,
        p1.dup,
      ],
    })

    part.media_type.should eq "multipart"
    part.media_sub_type.should eq "form-data"

    p1.name = "foo"
    p1.disposition = "form-data"

    p2 = p1.dup
    p2.name = "bar[baz][0]"
    p2.disposition = "form-data"

    p3 = p1.dup
    p3.name = "bar[baz][qux]"
    p3.disposition = "form-data"

    p4 = p1.dup
    p4.name = "2"
    p4.disposition = "form-data"

    p5 = p1.dup
    p5.name = "quux[0]"
    p5.disposition = "form-data"

    p6 = p1.dup
    p6.name = "quux[1]"
    p6.disposition = "form-data"

    part.parts.should eq [p1, p2, p3, p4, p5, p6]
  end

  def test_disallowed_value_type : Nil
    expect_raises AMIME::Exception::InvalidArgument, "The value of the form field 'foo[qux][quux]' can only be a String, Hash, Array, or AMIME::Part::Text instance, got 'Int32'." do
      AMIME::Part::Multipart::Form.new({
        "foo" => {
          "bar" => "baz",
          "qux" => {
            "quux" => 1,
          },
        },
      })
    end
  end

  def test_to_s : Nil
    p = AMIME::Part::Data.from_path file_path = "#{__DIR__}/../../fixtures/mimetypes/test.gif"
    p.body_to_s.should eq Base64.encode(File.read file_path)
  end

  def test_content_line_length : Nil
    part = AMIME::Part::Multipart::Form.new({
      "foo" => AMIME::Part::Data.new(foo = "foo" * 1000, "foo.txt", "text/plain"),
      "bar" => bar = "bar" * 1000,
    })

    part.parts[0].body_to_s.should eq foo
    part.parts[1].body_to_s.should eq bar
  end

  def test_boundary_content_type_header : Nil
    AMIME::Part::Multipart::Form.new({
      "file" => AMIME::Part::Data.new("data.csv", "data.csv", "text/csv"),
    })
      .prepared_headers
      .to_a
      .first
      .should match /^content-type: multipart\/form-data; boundary=[a-zA-Z0-9\-_]{50}$/ # 26 `-` + 18 bytes of base64 data
  end

  def test_body_to_s : Nil
    string_lines = AMIME::Part::Multipart::Form.new({
      "file" => AMIME::Part::Data.new("data.csv", "data.csv", "text/csv"),
    })
      .body_to_s
      .lines

    string_lines[0].should match /^[a-zA-Z0-9\-_]{50}$/ # 26 `-` + 18 bytes of base64 data
    string_lines[1].should eq "content-type: text/csv"
    string_lines[2].should eq "content-transfer-encoding: 8bit"
    string_lines[3].should eq %(content-disposition: form-data; name="file"; filename="data.csv")
    string_lines[4].should be_empty
    string_lines[5].should eq "data.csv"
    string_lines[6].should match /^[a-zA-Z0-9\-_]{50}$/ # 26 `-` + 18 bytes of base64 data
  end
end
