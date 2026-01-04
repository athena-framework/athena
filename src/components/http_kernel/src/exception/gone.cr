require "./http_exception"

class Athena::HTTPKernel::Exception::Gone < Athena::HTTPKernel::Exception::HTTPException
  def initialize(message : String, cause : ::Exception? = nil, headers : ::HTTP::Headers = ::HTTP::Headers.new)
    super :gone, message, cause, headers
  end
end
