require "./http_exception"

class Athena::Framework::Exceptions::SuspiciousOperation < Athena::Framework::Exceptions::BadRequest
  def initialize(message : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super message, cause, headers
  end
end
