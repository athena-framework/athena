require "./http_exception"

class Athena::Framework::Exceptions::NotAcceptable < Athena::Framework::Exceptions::HTTPException
  def initialize(message : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :not_acceptable, message, cause, headers
  end
end
