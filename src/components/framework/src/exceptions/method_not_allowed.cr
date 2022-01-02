require "./http_exception"

class Athena::Framework::Exceptions::MethodNotAllowed < Athena::Framework::Exceptions::HTTPException
  def initialize(
    allow : Array(String),
    message : String,
    cause : Exception? = nil,
    headers : HTTP::Headers = HTTP::Headers.new
  )
    headers["allow"] = allow.join ", ", &.upcase

    super :method_not_allowed, message, cause, headers
  end
end
