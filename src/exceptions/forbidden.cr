require "./http_exception"

class Athena::Framework::Exceptions::Forbidden < Athena::Framework::Exceptions::HTTPException
  def initialize(message : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :forbidden, message, cause, headers
  end
end
