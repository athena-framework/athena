require "./http_exception"

class Athena::Framework::Exceptions::NotFound < Athena::Framework::Exceptions::HTTPException
  def initialize(message : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :not_found, message, cause, headers
  end
end
