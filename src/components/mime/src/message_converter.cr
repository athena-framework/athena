module Athena::MIME::MessageConverter
  # Utility method to convert `AMIME::Message`s to `AMIME::Email`s.
  def self.to_email(message : AMIME::Message) : AMIME::Email
    return message if message.is_a? AMIME::Email

    body = message.body

    case body
    when AMIME::Part::Text                   then return self.create_email_from_text_part message, body
    when AMIME::Part::Multipart::Alternative then return self.create_email_from_alternative_part message, body
    when AMIME::Part::Multipart::Related     then return self.create_email_from_related_part message, body
    when AMIME::Part::Multipart::Mixed
      parts = body.parts

      email = case part = parts.first?
              when AMIME::Part::Multipart::Related     then self.create_email_from_related_part message, part
              when AMIME::Part::Multipart::Alternative then self.create_email_from_alternative_part message, part
              when AMIME::Part::Text                   then self.create_email_from_text_part message, part
              else
                raise AMIME::Exception::Runtime.new "Unable to create an Email from an instance of '#{message.class}' as the body is too complex."
              end

      parts.shift

      return self.add_parts email, parts
    end

    raise AMIME::Exception::Runtime.new "Unable to create an Email from an instance of '#{message.class}' as the body is too complex."
  end

  private def self.create_email_from_text_part(message : AMIME::Message, part : AMIME::Part::Text) : AMIME::Email
    if "text" == part.media_type && "plain" == part.media_sub_type
      return AMIME::Email
        .new(message.headers.clone)
        .text(part.body, part.prepared_headers.header_parameter("content-type", "charset") || "UTF-8")
    end

    if "text" == part.media_type && "html" == part.media_sub_type
      return AMIME::Email
        .new(message.headers.clone)
        .html(part.body, part.prepared_headers.header_parameter("content-type", "charset") || "UTF-8")
    end

    raise AMIME::Exception::Runtime.new "Unable to create an Email from an instance of '#{message.class}' as the body is too complex."
  end

  private def self.create_email_from_alternative_part(message : AMIME::Message, part : AMIME::Part::Multipart::Alternative) : AMIME::Email
    parts = part.parts

    if 2 == parts.size &&
       (first_part = parts[0]).is_a?(AMIME::Part::Text) &&
       "text" == first_part.media_type && "plain" == first_part.media_sub_type &&
       (second_part = parts[1]).is_a?(AMIME::Part::Text) &&
       "text" == second_part.media_type && "html" == second_part.media_sub_type
      return AMIME::Email
        .new(message.headers.clone)
        .text(first_part.body, first_part.prepared_headers.header_parameter("content-type", "charset") || "UTF-8")
        .html(second_part.body, first_part.prepared_headers.header_parameter("content-type", "charset") || "UTF-8")
    end

    raise AMIME::Exception::Runtime.new "Unable to create an Email from an instance of '#{message.class}' as the body is too complex."
  end

  private def self.create_email_from_related_part(message : AMIME::Message, part : AMIME::Part::Multipart::Related) : AMIME::Email
    parts = part.parts

    first_part = parts.first?

    email = case first_part = parts.first?
            when AMIME::Part::Multipart::Alternative then self.create_email_from_alternative_part message, first_part
            when AMIME::Part::Text                   then self.create_email_from_text_part message, first_part
            else
              raise AMIME::Exception::Runtime.new "Unable to create an Email from an instance of '#{message.class}' as the body is too complex."
            end

    parts.shift

    self.add_parts email, parts
  end

  private def self.add_parts(email : AMIME::Email, parts : Enumerable(AMIME::Part::Abstract)) : AMIME::Email
    parts.each do |part|
      unless part.is_a? AMIME::Part::Data
        raise AMIME::Exception::Runtime.new "Unable to create an Email from an instance of '#{email.class}' as the body is too complex."
      end

      email.add_part part
    end

    email
  end
end
