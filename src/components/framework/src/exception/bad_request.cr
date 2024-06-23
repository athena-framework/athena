require "./http_exception"

class Athena::Framework::Exception::BadRequest < Athena::Framework::Exception::HTTPException
  def initialize(message : String, cause : ::Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :bad_request, message, cause, headers
  end
end
