require "./http_exception"

class Athena::Framework::Exception::UnprocessableEntity < Athena::Framework::Exception::HTTPException
  def initialize(message : String, cause : ::Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :unprocessable_entity, message, cause, headers
  end
end
