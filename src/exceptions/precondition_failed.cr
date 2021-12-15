require "./http_exception"

class Athena::Framework::Exceptions::PreconditionFailed < Athena::Framework::Exceptions::HTTPException
  def initialize(message : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :precondition_failed, message, cause, headers
  end
end
