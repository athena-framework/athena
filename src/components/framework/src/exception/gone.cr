require "./http_exception"

class Athena::Framework::Exception::Gone < Athena::Framework::Exception::HTTPException
  def initialize(message : String, cause : ::Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :gone, message, cause, headers
  end
end
