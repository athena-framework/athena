require "./http_exception"

class Athena::HTTPKernel::Exception::NotImplemented < Athena::HTTPKernel::Exception::HTTPException
  def initialize(message : String, cause : ::Exception? = nil, headers : ::HTTP::Headers = ::HTTP::Headers.new)
    super :not_implemented, message, cause, headers
  end
end
