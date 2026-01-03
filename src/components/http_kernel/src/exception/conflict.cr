require "./http_exception"

class Athena::HTTPKernel::Exception::Conflict < Athena::HTTPKernel::Exception::HTTPException
  def initialize(message : String, cause : ::Exception? = nil, headers : ::HTTP::Headers = ::HTTP::Headers.new)
    super :conflict, message, cause, headers
  end
end
