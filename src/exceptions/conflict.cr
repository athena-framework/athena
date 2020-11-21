require "./http_exception"

class Athena::Routing::Exceptions::Conflict < Athena::Routing::Exceptions::HTTPException
  def initialize(message : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :conflict, message, cause, headers
  end
end
