# Represents a `related` part.
class Athena::MIME::Part::Multipart::Related < Athena::MIME::Part::AbstractMultipart
  @main_part : AMIME::Part::Abstract

  def initialize(
    @main_part : AMIME::Part::Abstract,
    parts : Enumerable(AMIME::Part::Abstract),
  )
    self.prepare_parts parts

    super parts
  end

  # :inherit:
  def media_sub_type : String
    "related"
  end

  # :inherit:
  def parts : Array(AMIME::Part::Abstract)
    super.unshift @main_part
  end

  private def generate_content_id : String
    "#{Random::Secure.hex(16)}@athena"
  end

  private def prepare_parts(parts : Enumerable(AMIME::Part::Abstract)) : Nil
    parts.each do |part|
      headers = part.headers
      unless headers.has_key? "content-id"
        headers.upsert "content-id", self.generate_content_id, ->headers.add_id_header(String, String)
      end
    end
  end
end
