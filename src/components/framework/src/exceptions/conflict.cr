require "./http_exception"

class Athena::Framework::Exceptions::Conflict < Athena::Framework::Exceptions::HTTPException
  def initialize(message : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :conflict, message, cause, headers
  end
end
