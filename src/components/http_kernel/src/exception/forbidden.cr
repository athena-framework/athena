require "./http_exception"

class Athena::HTTPKernel::Exception::Forbidden < Athena::HTTPKernel::Exception::HTTPException
  def initialize(message : String, cause : ::Exception? = nil, headers : ::HTTP::Headers = ::HTTP::Headers.new)
    super :forbidden, message, cause, headers
  end
end
