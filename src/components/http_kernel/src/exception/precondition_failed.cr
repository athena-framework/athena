require "./http_exception"

class Athena::HTTPKernel::Exception::PreconditionFailed < Athena::HTTPKernel::Exception::HTTPException
  def initialize(message : String, cause : ::Exception? = nil, headers : ::HTTP::Headers = ::HTTP::Headers.new)
    super :precondition_failed, message, cause, headers
  end
end
