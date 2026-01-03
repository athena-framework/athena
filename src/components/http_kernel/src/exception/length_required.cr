require "./http_exception"

class Athena::HTTPKernel::Exception::LengthRequired < Athena::HTTPKernel::Exception::HTTPException
  def initialize(message : String, cause : ::Exception? = nil, headers : ::HTTP::Headers = ::HTTP::Headers.new)
    super :length_required, message, cause, headers
  end
end
