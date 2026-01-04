require "./http_exception"

class Athena::HTTPKernel::Exception::UnprocessableEntity < Athena::HTTPKernel::Exception::HTTPException
  def initialize(message : String, cause : ::Exception? = nil, headers : ::HTTP::Headers = ::HTTP::Headers.new)
    super :unprocessable_entity, message, cause, headers
  end
end
