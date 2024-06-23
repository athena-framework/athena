require "./http_exception"

class Athena::Framework::Exception::NotImplemented < Athena::Framework::Exception::HTTPException
  def initialize(message : String, cause : ::Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super :not_implemented, message, cause, headers
  end
end
