require "./http_exception"

class Athena::Framework::Exceptions::UnsupportedMediaType < Athena::Framework::Exceptions::HTTPException
  def initialize(message : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :unsupported_media_type, message, cause, headers
  end
end
