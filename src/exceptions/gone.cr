require "./http_exception"

class Athena::Framework::Exceptions::Gone < Athena::Framework::Exceptions::HTTPException
  def initialize(message : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :gone, message, cause, headers
  end
end
