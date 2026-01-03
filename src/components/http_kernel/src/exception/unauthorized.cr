require "./http_exception"

class Athena::HTTPKernel::Exception::Unauthorized < Athena::HTTPKernel::Exception::HTTPException
  # See `Athena::HTTPKernel::Exception::HTTPException#new`.
  #
  # Includes a `www-authenticate` header with the provided *challenge*.
  def initialize(message : String, challenge : String, cause : ::Exception? = nil, headers : ::HTTP::Headers = ::HTTP::Headers.new)
    headers["www-authenticate"] = challenge

    super :unauthorized, message, cause, headers
  end
end
