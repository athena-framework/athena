require "./http_exception"

class Athena::Routing::Exceptions::PreconditionFailed < Athena::Routing::Exceptions::HTTPException
  def initialize(message : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :precondition_failed, message, cause, headers
  end
end
