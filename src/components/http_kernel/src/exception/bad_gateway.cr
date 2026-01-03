require "./http_exception"

class Athena::HTTPKernel::Exception::BadGateway < Athena::HTTPKernel::Exception::HTTPException
  def initialize(message : String, cause : ::Exception? = nil, headers : ::HTTP::Headers = ::HTTP::Headers.new)
    super :bad_gateway, message, cause, headers
  end
end
