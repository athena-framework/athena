require "./http_exception"

class Athena::Framework::Exception::ServiceUnavailable < Athena::Framework::Exception::HTTPException
  # See `Athena::Framework::Exception::HTTPException#new`.
  #
  # If *retry_after* is provided, adds a `retry-after` header that represents the number of seconds or HTTP-date after which the request may be retried.
  def initialize(message : String, retry_after : Number | String | Nil = nil, cause : ::Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    headers["retry-after"] = retry_after.to_s if retry_after

    super :service_unavailable, message, cause, headers
  end
end
