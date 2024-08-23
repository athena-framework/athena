require "./http_exception"

class Athena::Framework::Exception::SuspiciousOperation < Athena::Framework::Exception::BadRequest
  def initialize(message : String, cause : ::Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super message, cause, headers
  end
end
