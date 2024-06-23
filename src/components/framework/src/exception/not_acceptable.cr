require "./http_exception"

class Athena::Framework::Exception::NotAcceptable < Athena::Framework::Exception::HTTPException
  def initialize(message : String, cause : ::Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :not_acceptable, message, cause, headers
  end
end
