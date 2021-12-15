require "./http_exception"

class Athena::Framework::Exceptions::UnprocessableEntity < Athena::Framework::Exceptions::HTTPException
  def initialize(message : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :unprocessable_entity, message, cause, headers
  end
end
