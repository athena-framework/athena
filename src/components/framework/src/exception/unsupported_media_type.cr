require "./http_exception"

class Athena::Framework::Exception::UnsupportedMediaType < Athena::Framework::Exception::HTTPException
  def initialize(message : String, cause : ::Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :unsupported_media_type, message, cause, headers
  end
end
