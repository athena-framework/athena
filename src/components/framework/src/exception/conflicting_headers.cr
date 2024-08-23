require "./http_exception"

class Athena::Framework::Exception::ConflictingHeaders < Athena::Framework::Exception::BadRequest
  def initialize(message : String, cause : ::Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super message, cause, headers
  end
end
