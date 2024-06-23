require "./http_exception"

class Athena::Framework::Exception::Conflict < Athena::Framework::Exception::HTTPException
  def initialize(message : String, cause : ::Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :conflict, message, cause, headers
  end
end
