require "./http_exception"

class Athena::HTTPKernel::Exception::NotFound < Athena::HTTPKernel::Exception::HTTPException
  def initialize(message : String, cause : ::Exception? = nil, headers : ::HTTP::Headers = ::HTTP::Headers.new)
    super :not_found, message, cause, headers
  end
end
