require "./http_exception"

class Athena::Framework::Exception::Forbidden < Athena::Framework::Exception::HTTPException
  def initialize(message : String, cause : ::Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :forbidden, message, cause, headers
  end
end
