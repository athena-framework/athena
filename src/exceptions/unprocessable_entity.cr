require "./http_exception"

class Athena::Routing::Exceptions::UnprocessableEntity < Athena::Routing::Exceptions::HTTPException
  def initialize(message : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :unprocessable_entity, message, cause, headers
  end
end
