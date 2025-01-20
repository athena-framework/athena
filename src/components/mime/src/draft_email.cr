# Represent an un-sent `AMIME::Email` message.
#
# ```
# draft_email = AMIME::DraftEmail
#   .new
#   .to("you@example.com")
#   .subject("Important Notification")
#   .text("Lorem ipsum...")
#
# # ...
# ```
class Athena::MIME::DraftEmail < Athena::MIME::Email
  def initialize(
    headers : AMIME::Header::Collection? = nil,
    body : AMIME::Part::Abstract? = nil,
  )
    super

    @headers.add_text_header "x-unsent", "1"
  end

  # :inherit:
  def prepared_headers : AMIME::Header::Collection
    # Override default behavior as draft emails do not need from/sender/date/message-id headers.
    # These are added by the client that sends the email.

    headers = @headers.clone

    unless headers.has_key? "mime-version"
      headers.add_text_header "mime-version", "1.0"
    end

    headers.delete "bcc"

    headers
  end
end
