require "./http_exception"

class Athena::Routing::Exceptions::Unauthorized < Athena::Routing::Exceptions::HTTPException
  # See `Athena::Routing::Exceptions::HTTPException#new`.
  #
  # Includes a `www-authenticate` header with the provided *challenge*.
  def initialize(message : String, challenge : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    headers["www-authenticate"] = challenge

    super :unauthorized, message, cause, headers
  end
end
