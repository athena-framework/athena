require "./http_exception"

class Athena::HTTPKernel::Exception::MethodNotAllowed < Athena::HTTPKernel::Exception::HTTPException
  def initialize(
    allow : Array(String),
    message : String,
    cause : ::Exception? = nil,
    headers : ::HTTP::Headers = ::HTTP::Headers.new,
  )
    headers["allow"] = allow.join ", ", &.upcase

    super :method_not_allowed, message, cause, headers
  end
end
