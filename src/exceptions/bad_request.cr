require "./http_exception"

class Athena::Framework::Exceptions::BadRequest < Athena::Framework::Exceptions::HTTPException
  def initialize(message : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :bad_request, message, cause, headers
  end
end
