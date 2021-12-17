require "./http_exception"

class Athena::Framework::Exceptions::Unauthorized < Athena::Framework::Exceptions::HTTPException
  # See `Athena::Framework::Exceptions::HTTPException#new`.
  #
  # Includes a `www-authenticate` header with the provided *challenge*.
  def initialize(message : String, challenge : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    headers["www-authenticate"] = challenge

    super :unauthorized, message, cause, headers
  end
end
