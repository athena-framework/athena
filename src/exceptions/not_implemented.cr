require "./http_exception"

class Athena::Routing::Exceptions::NotImplemented < Athena::Routing::Exceptions::HTTPException
  def initialize(message : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :not_implemented, message, cause, headers
  end
end
