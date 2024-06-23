require "./http_exception"

class Athena::Framework::Exception::LengthRequired < Athena::Framework::Exception::HTTPException
  def initialize(message : String, cause : ::Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :length_required, message, cause, headers
  end
end
