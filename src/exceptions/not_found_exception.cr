require "./http_exception"

class Athena::Routing::Exceptions::NotFound < Athena::Routing::Exceptions::HTTPException
  def initialize(message : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :not_found, message, cause, headers
  end
end
