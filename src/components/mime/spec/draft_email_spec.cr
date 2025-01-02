require "./spec_helper"

struct DraftEmailTest < ASPEC::TestCase
  def test_can_have_just_body : Nil
    email = AMIME::DraftEmail.new.text("text content").to_s

    email.should contain "text content"
    email.should contain "mime-version: 1.0"
    email.should contain "x-unsent: 1"
  end

  def test_removes_bcc : Nil
    email = AMIME::DraftEmail.new.text("text content").bcc("foo@example.com").to_s

    email.should_not contain "foo@example.com"
  end

  def test_must_have_body : Nil
    expect_raises AMIME::Exception::Logic, "A message must have a text or an HTML part or attachments." do
      AMIME::DraftEmail.new.to_s
    end
  end

  def test_ensure_validity_always_fails : Nil
    expect_raises AMIME::Exception::Logic, "Cannot send messages marked as 'draft'." do
      AMIME::DraftEmail.new.text("text content").to("you@example.com").from("me@example.com").ensure_validity
    end
  end
end
