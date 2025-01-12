class Athena::MIME::Part::Message < Athena::MIME::Part::Data
  @message : AMIME::Message

  def initialize(
    @message : AMIME::Message
  )
    super "", %(#{@message.headers.header_body("subject")}.eml)
  end

  # :inherit:
  def media_type : String
    "message"
  end

  # :inherit:
  def media_sub_type : String
    "rfc822"
  end

  def body : String
    @message.body.to_s
  end

  def body_to_s : String
    self.body
  end
end
