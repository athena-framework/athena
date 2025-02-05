require "./spec_helper"

struct MessageConverterTest < ASPEC::TestCase
  def test_to_email_email_argument : Nil
    email = self.new_email
    AMIME::MessageConverter.to_email(email).should be email
  end

  def test_requires_conversion : Nil
    file = File.read "#{__DIR__}/fixtures/mimetypes/test.gif"

    self.assert_conversion(new_email.text("text content"))
    self.assert_conversion(new_email.html(%(HTML content <img src="cid:test.gif" />)))
    self.assert_conversion(new_email.text("text content").html(%(HTML content <img src="cid:test.gif" />)))
    self.assert_conversion(new_email
      .text("text content")
      .html(%(HTML content <img src="cid:test.gif" />))
      .add_part(AMIME::Part::Data.new(file, "test.gif", "image/gif").as_inline)
    )
    self.assert_conversion(new_email
      .text("text content")
      .html(%(HTML content <img src="cid:test.gif" />))
      .add_part(AMIME::Part::Data.new(file, "test_attached.gif", "image/gif"))
    )
    self.assert_conversion(new_email
      .text("text content")
      .html(%(HTML content <img src="cid:test.gif" />))
      .add_part(AMIME::Part::Data.new(file, "test.gif", "image/gif").as_inline)
      .add_part(AMIME::Part::Data.new(file, "test_attached.gif", "image/gif"))
    )
    self.assert_conversion(new_email
      .text("text content")
      .add_part(AMIME::Part::Data.new(file, "test_attached.gif", "image/gif"))
    )
    self.assert_conversion(new_email
      .html(%(HTML content <img src="cid:test.gif" />))
      .add_part(AMIME::Part::Data.new(file, "test_attached.gif", "image/gif"))
    )
    self.assert_conversion(new_email
      .html(%(HTML content <img src="cid:test.gif" />))
      .add_part(AMIME::Part::Data.new(file, "test_attached.gif", "image/gif").as_inline)
    )
    self.assert_conversion(new_email
      .text("text content")
      .add_part(AMIME::Part::Data.new(file, "test_attached.gif", "image/gif").as_inline)
    )
  end

  private def assert_conversion(expected : AMIME::Email) : Nil
    message = AMIME::Message.new expected.headers, expected.generate_body
    converted = AMIME::MessageConverter.to_email message

    if html_body = expected.html_body
      html_body.should match /HTML content <img src="cid:[\w\.]+" \/>/
      expected.html "html content"
      converted.html "html content"
    end

    pointerof(expected.@cached_body).value = nil
    pointerof(converted.@cached_body).value = nil

    converted.should eq expected
  end

  private def new_email : AMIME::Email
    AMIME::Email.new.from("me@example.com").to("you@example.com")
  end
end
