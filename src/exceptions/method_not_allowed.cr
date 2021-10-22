require "./http_exception"

class Athena::Framework::Exceptions::MethodNotAllowed < Athena::Framework::Exceptions::HTTPException
  def initialize(message : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :method_not_allowed, message, cause, headers
  end
end
