require "./http_exception"

class Athena::Routing::Exceptions::NotAcceptable < Athena::Routing::Exceptions::HTTPException
  def initialize(message : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :not_acceptable, message, cause, headers
  end
end
