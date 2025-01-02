class Athena::MIME::Message
  property headers : AMIME::Header::Collection
  property body : AMIME::Part::Abstract?

  def initialize(
    headers : AMIME::Header::Collection? = nil,
    @body : AMIME::Part::Abstract? = nil
  )
    # TODO: Need to clone this?
    @headers = headers || AMIME::Header::Collection.new
  end

  def prepared_headers : AMIME::Header::Collection
    headers = @headers.clone

    unless headers.has_key? "from"
      unless headers.has_key? "sender"
        raise AMIME::Exception::Logic.new "An email must have a 'from' or a 'sender' header."
      end

      headers.add_mailbox_list_header "from", [headers["sender", AMIME::Header::Mailbox].body]
    end

    unless headers.has_key? "mime-version"
      headers.add_text_header "mime-version", "1.0"
    end

    unless headers.has_key? "date"
      headers.add_date_header "date", Time.utc
    end

    # Determine the "real" sender
    if !headers.has_key?("sender") && (froms = headers["from", AMIME::Header::MailboxList].body) && froms.size > 1
      headers.add_mailbox_header "sender", froms.first
    end

    unless headers.has_key? "message-id"
      headers.add_id_header "message-id", self.generate_message_id
    end

    # Remove bcc which should _NOT_ be part of the sent message
    headers.delete "bcc"

    headers
  end

  def to_s(io : IO) : Nil
    body = self.body || AMIME::Part::Text.new ""

    self.prepared_headers.to_s io
    body.to_s io
  end

  def ensure_validity : Nil
    if (!(tos = @headers.header_body("to")) || tos.as(Array(AMIME::Address)).empty?) && (!(ccs = @headers.header_body("cc")) || ccs.as(Array(AMIME::Address)).empty?) && (!(bccs = @headers.header_body("bcc")) || bccs.as(Array(AMIME::Address)).empty?)
      raise AMIME::Exception::Logic.new "An email must have a 'to', 'cc', or 'bcc' header."
    end

    if (!(froms = @headers.header_body("from")) || froms.as(Array(AMIME::Address)).empty?) && !@headers.header_body("sender")
      raise AMIME::Exception::Logic.new "An email must have a 'from' or a 'sender' header."
    end
  end

  def generate_message_id : String
    sender = if sender_header = @headers["sender", AMIME::Header::Mailbox]?
               sender_header.body
             elsif from_header = @headers["from", AMIME::Header::MailboxList]?
               if (froms = from_header.body).empty?
                 raise AMIME::Exception::Logic.new "A 'from' header must have at least one email address."
               end

               froms.first
             else
               raise AMIME::Exception::Logic.new "An email must have a 'from' or 'sender' header."
             end

    "#{Random::Secure.hex(16)}@#{sender.address.partition('@').last}"
  end
end
