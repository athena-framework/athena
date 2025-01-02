require "./spec_helper"

struct EmailTest < ASPEC::TestCase
  def test_subject : Nil
    e = AMIME::Email.new
    e.subject "Subject"
    e.subject.should eq "Subject"
  end

  def test_date : Nil
    e = AMIME::Email.new
    e.date now = Time.utc
    e.date.should eq now
  end

  def test_return_path : Nil
    e = AMIME::Email.new
    e.return_path "foo@example.com"
    e.return_path.should eq AMIME::Address.new("foo@example.com")
  end

  def test_sender : Nil
    e = AMIME::Email.new
    e.sender "foo@example.com"
    e.sender.should eq AMIME::Address.new "foo@example.com"

    e.sender s = AMIME::Address.new("bar@example.com")
    e.sender.should eq s
  end

  def test_from : Nil
    e = AMIME::Email.new
    helene = AMIME::Address.new "helene@example.com"
    thomas = AMIME::Address.new "thomas@example.com"
    caramel = AMIME::Address.new "caramel@example.com"

    e.from "fred@example.com", helene, thomas

    v = e.from
    v.size.should eq 3
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas

    e.add_from "lucas@example.com", caramel

    v = e.from
    v.size.should eq 5
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas
    v[3].should eq AMIME::Address.new "lucas@example.com"
    v[4].should eq caramel

    e = AMIME::Email.new
    e.add_from "lucas@example.com", caramel

    v = e.from
    v.size.should eq 2
    v[0].should eq AMIME::Address.new "lucas@example.com"
    v[1].should eq caramel

    e = AMIME::Email.new
    e.from "lucas@example.com"
    e.from caramel

    v = e.from
    v.size.should eq 1
    v[0].should eq caramel
  end

  def test_reply_to : Nil
    e = AMIME::Email.new
    helene = AMIME::Address.new "helene@example.com"
    thomas = AMIME::Address.new "thomas@example.com"
    caramel = AMIME::Address.new "caramel@example.com"

    e.reply_to "fred@example.com", helene, thomas

    v = e.reply_to
    v.size.should eq 3
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas

    e.add_reply_to "lucas@example.com", caramel

    v = e.reply_to
    v.size.should eq 5
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas
    v[3].should eq AMIME::Address.new "lucas@example.com"
    v[4].should eq caramel

    e = AMIME::Email.new
    e.add_reply_to "lucas@example.com", caramel

    v = e.reply_to
    v.size.should eq 2
    v[0].should eq AMIME::Address.new "lucas@example.com"
    v[1].should eq caramel

    e = AMIME::Email.new
    e.reply_to "lucas@example.com"
    e.reply_to caramel

    v = e.reply_to
    v.size.should eq 1
    v[0].should eq caramel
  end

  def test_to : Nil
    e = AMIME::Email.new
    helene = AMIME::Address.new "helene@example.com"
    thomas = AMIME::Address.new "thomas@example.com"
    caramel = AMIME::Address.new "caramel@example.com"

    e.to "fred@example.com", helene, thomas

    v = e.to
    v.size.should eq 3
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas

    e.add_to "lucas@example.com", caramel

    v = e.to
    v.size.should eq 5
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas
    v[3].should eq AMIME::Address.new "lucas@example.com"
    v[4].should eq caramel

    e = AMIME::Email.new
    e.add_to "lucas@example.com", caramel

    v = e.to
    v.size.should eq 2
    v[0].should eq AMIME::Address.new "lucas@example.com"
    v[1].should eq caramel

    e = AMIME::Email.new
    e.to "lucas@example.com"
    e.to caramel

    v = e.to
    v.size.should eq 1
    v[0].should eq caramel
  end

  def test_cc : Nil
    e = AMIME::Email.new
    helene = AMIME::Address.new "helene@example.com"
    thomas = AMIME::Address.new "thomas@example.com"
    caramel = AMIME::Address.new "caramel@example.com"

    e.cc "fred@example.com", helene, thomas

    v = e.cc
    v.size.should eq 3
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas

    e.add_cc "lucas@example.com", caramel

    v = e.cc
    v.size.should eq 5
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas
    v[3].should eq AMIME::Address.new "lucas@example.com"
    v[4].should eq caramel

    e = AMIME::Email.new
    e.add_cc "lucas@example.com", caramel

    v = e.cc
    v.size.should eq 2
    v[0].should eq AMIME::Address.new "lucas@example.com"
    v[1].should eq caramel

    e = AMIME::Email.new
    e.cc "lucas@example.com"
    e.cc caramel

    v = e.cc
    v.size.should eq 1
    v[0].should eq caramel
  end

  def test_bcc : Nil
    e = AMIME::Email.new
    helene = AMIME::Address.new "helene@example.com"
    thomas = AMIME::Address.new "thomas@example.com"
    caramel = AMIME::Address.new "caramel@example.com"

    e.bcc "fred@example.com", helene, thomas

    v = e.bcc
    v.size.should eq 3
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas

    e.add_bcc "lucas@example.com", caramel

    v = e.bcc
    v.size.should eq 5
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas
    v[3].should eq AMIME::Address.new "lucas@example.com"
    v[4].should eq caramel

    e = AMIME::Email.new
    e.add_bcc "lucas@example.com", caramel

    v = e.bcc
    v.size.should eq 2
    v[0].should eq AMIME::Address.new "lucas@example.com"
    v[1].should eq caramel

    e = AMIME::Email.new
    e.bcc "lucas@example.com"
    e.bcc caramel

    v = e.bcc
    v.size.should eq 1
    v[0].should eq caramel
  end

  def test_priority : Nil
    e = AMIME::Email.new
    e.priority.should eq AMIME::Email::Priority::NORMAL

    e.priority :high
    e.priority.should eq AMIME::Email::Priority::HIGH

    e.priority AMIME::Email::Priority.new(123)
    e.priority.should eq AMIME::Email::Priority::NORMAL
  end

  def test_raises_when_body_is_empty : Nil
    expect_raises AMIME::Exception::Logic, "A message must have a text or an HTML part or attachments." do
      AMIME::Email.new.body
    end
  end

  def test_body : Nil
    e = AMIME::Email.new
    e.body = text = AMIME::Part::Text.new "content"
    e.body.should eq text
  end

  def test_generate_body_with_text_only : Nil
    text = AMIME::Part::Text.new "text content"
    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.text "text content"
    e.body.should eq text
    e.text_body.should eq "text content"
  end

  def test_generate_body_with_html_only : Nil
    text = AMIME::Part::Text.new "html content", sub_type: "html"
    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.html "html content"
    e.body.should eq text
    e.html_body.should eq "html content"
  end

  def test_generate_body_with_text_and_html : Nil
    text = AMIME::Part::Text.new "text content"
    html = AMIME::Part::Text.new "html content", sub_type: "html"
    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.text "text content"
    e.html "html content"
    e.body.should eq AMIME::Part::Multipart::Alternative.new(text, html)
  end

  def test_generate_body_with_text_and_html_non_utf8 : Nil
    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.text "text content", "iso-8859-1"
    e.html "html content", "iso-8859-1"

    e.text_charset.should eq "iso-8859-1"
    e.html_charset.should eq "iso-8859-1"

    e.body.should eq AMIME::Part::Multipart::Alternative.new(
      AMIME::Part::Text.new("text content", "iso-8859-1"),
      AMIME::Part::Text.new("html content", "iso-8859-1", "html"),
    )
  end

  def test_geneate_body_with_text_content_and_attachment : Nil
    text, _, file_part, file = self.generate_some_parts

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.add_part AMIME::Part::Data.new(file)
    e.text "text content"

    e.body.should eq AMIME::Part::Multipart::Mixed.new text, file_part
  end

  def test_geneate_body_with_html_content_and_attachment : Nil
    _, html, file_part, file = self.generate_some_parts

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.add_part AMIME::Part::Data.new(file)
    e.html "html content"

    e.body.should eq AMIME::Part::Multipart::Mixed.new html, file_part
  end

  def test_geneate_body_with_html_content_and_inlined_image_not_reference : Nil
    _, html = self.generate_some_parts
    image_part = AMIME::Part::Data.new image = ::File.open("#{__DIR__}/fixtures/mimetypes/test.gif", "r")
    image_part.as_inline

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.add_part AMIME::Part::Data.new(image).as_inline
    e.html "html content"

    e.body.should eq AMIME::Part::Multipart::Mixed.new(html, image_part)
  end

  def test_geneate_body_attached_file_only : Nil
    _, _, file_part, file = self.generate_some_parts

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.add_part AMIME::Part::Data.new file

    e.body.should eq AMIME::Part::Multipart::Mixed.new file_part
  end

  def test_geneate_body_inline_image_only : Nil
    image_part = AMIME::Part::Data.new image = ::File.open("#{__DIR__}/fixtures/mimetypes/test.gif", "r")
    image_part.as_inline

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.add_part AMIME::Part::Data.new(image).as_inline

    e.body.should eq AMIME::Part::Multipart::Mixed.new image_part
  end

  def test_geneate_body_with_text_and_html_content_and_attachment : Nil
    text, html, file_part, file = self.generate_some_parts

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.text "text content"
    e.html "html content"
    e.add_part AMIME::Part::Data.new file

    e.body.should eq AMIME::Part::Multipart::Mixed.new(AMIME::Part::Multipart::Alternative.new(text, html), file_part)
  end

  def test_geneate_body_with_text_and_html_content_and_attachment_and_attached_image_not_referenced : Nil
    text, html, file_part, file, image_part, image = self.generate_some_parts

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.text "text content"
    e.html "html content"
    e.add_part AMIME::Part::Data.new(file)
    e.add_part AMIME::Part::Data.new(image, "test.gif")

    e.body.should eq AMIME::Part::Multipart::Mixed.new(AMIME::Part::Multipart::Alternative.new(text, html), file_part, image_part)
  end

  def test_geneate_body_with_text_and_attached_file_and_attached_image_not_referenced : Nil
    text, _, file_part, file, image_part, image = self.generate_some_parts

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.text "text content"
    e.add_part AMIME::Part::Data.new(file)
    e.add_part AMIME::Part::Data.new(image, "test.gif")

    e.body.should eq AMIME::Part::Multipart::Mixed.new(text, file_part, image_part)
  end

  def test_generate_body_with_text_and_html_and_attached_file_and_attached_image_not_referenced_via_cid : Nil
    text, _, file_part, file, image_part, image = self.generate_some_parts

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.html content = %(html content <img src="test.gif">)
    e.text "text content"
    e.add_part AMIME::Part::Data.new(file)
    e.add_part AMIME::Part::Data.new(image, "test.gif")
    full_html = AMIME::Part::Text.new content, sub_type: "html"

    e.body.should eq AMIME::Part::Multipart::Mixed.new(AMIME::Part::Multipart::Alternative.new(text, full_html), file_part, image_part)
  end

  def test_generate_body_with_text_and_html_and_attached_file_and_attached_image_referenced_via_cid : Nil
    _, _, file_part, file, _, image = self.generate_some_parts

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.html content = %(html content <img src="cid:test.gif">)
    e.text "text content"
    e.add_part AMIME::Part::Data.new(file)
    e.add_part AMIME::Part::Data.new(image, "test.gif")

    body = e.body.should be_a AMIME::Part::Multipart::Mixed
    (related = body.parts).size.should eq 2

    related_part = related[0].should be_a AMIME::Part::Multipart::Related
    related[1].should eq file_part

    (parts = related_part.parts).size.should eq 2

    alt_part = parts[0].should be_a AMIME::Part::Multipart::Alternative
    generated_html = alt_part.parts[1].should be_a AMIME::Part::Text
    data_part = parts[1].should be_a AMIME::Part::Data

    generated_html.body.should contain "cid:#{data_part.content_id}"
  end

  def test_generate_body_with_text_and_html_and_attached_file_and_attached_image_referenced_via_cid_and_content_id : Nil
    _, _, file_part, file, _, image = self.generate_some_parts

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.text "text content"
    e.add_part AMIME::Part::Data.new file
    img = AMIME::Part::Data.new image, "test.gif"
    e.add_part img
    e.html %(html content <img src="cid:#{img.content_id}">)

    body = e.body.should be_a AMIME::Part::Multipart::Mixed
    (related_parts = body.parts).size.should eq 2

    related_part = related_parts[0].should be_a AMIME::Part::Multipart::Related
    related_parts[1].should eq file_part

    (parts = related_part.parts).size.should eq 2
    parts[0].should be_a AMIME::Part::Multipart::Alternative
  end

  def test_generate_body_with_html_and_inlined_image_twice_referenced_via_cid : Nil
    # Inline image (twice) referenced in the HTML content
    content = IO::Memory.new %(html content <img src="cid:test.gif">)

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.html content

    # Embedding the same image twice results in one image only in the email
    image = ::File.open "#{__DIR__}/fixtures/mimetypes/test.gif", "r"
    e.add_part AMIME::Part::Data.new(image, "test.gif").as_inline
    e.add_part AMIME::Part::Data.new(image, "test.gif").as_inline

    body = e.body.should be_a AMIME::Part::Multipart::Related

    # 2 parts only, not 3 (text + 1 embedded image)
    (parts = body.parts).size.should eq 2
    parts[0].body_to_s.should match /html content <img src=3D"cid:\w+@athena">/

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.html %(<div background="cid:test.gif"></div>)
    e.add_part AMIME::Part::Data.new(image, "test.gif").as_inline

    body = e.body.should be_a AMIME::Part::Multipart::Related
    (parts = body.parts).size.should eq 2
    parts[0].body_to_s.should match /<div background=3D"cid:\w+@athena"><\/div>/
  end

  def test_attachments : Nil
    # Inline part
    contents = ::File.read path = "#{__DIR__}/fixtures/mimetypes/test"
    data_part = AMIME::Part::Data.new file = ::File.open(path), "test"
    inline = AMIME::Part::Data.new(contents, "test").as_inline

    e = AMIME::Email.new
    e.add_part AMIME::Part::Data.new file, "test"
    e.add_part AMIME::Part::Data.new(contents, "test").as_inline
    e.attachments.should eq [data_part, inline]

    # Inline part from path
    data_part = AMIME::Part::Data.from_path path, "test"
    inline = AMIME::Part::Data.from_path(path, "test").as_inline
    e = AMIME::Email.new
    e.add_part AMIME::Part::Data.new AMIME::Part::File.new(path)
    e.add_part AMIME::Part::Data.new(AMIME::Part::File.new(path)).as_inline

    e.attachments.map(&.body_to_s).should eq [data_part.body_to_s, inline.body_to_s]
    e.attachments.map(&.prepared_headers).should eq [data_part.prepared_headers, inline.prepared_headers]
  end

  def test_body_cache_same : Nil
    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.text "text content"

    body1 = e.body
    body2 = e.body

    # Must be the same instance so that DKIM sig is the same
    body1.should be body2
  end

  def test_body_cache_different : Nil
    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.text "text content"
    body1 = e.body
    e.html "<b>bar</b>"
    body2 = e.body

    # Must not be the same due to the content changing
    body1.should_not be body2
  end

  private def generate_some_parts : {AMIME::Part::Text, AMIME::Part::Text, AMIME::Part::Data, ::File, AMIME::Part::Data, ::File}
    text = AMIME::Part::Text.new "text content"
    html = AMIME::Part::Text.new "html content", sub_type: "html"
    file_part = AMIME::Part::Data.new file = ::File.open "#{__DIR__}/fixtures/mimetypes/test", "r"
    image_part = AMIME::Part::Data.new (image = ::File.open("#{__DIR__}/fixtures/mimetypes/test.gif", "r")), "test.gif"

    {text, html, file_part, file, image_part, image}
  end
end
