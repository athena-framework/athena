require "./http_exception"

class Athena::Routing::Exceptions::ServiceUnavailable < Athena::Routing::Exceptions::HTTPException
  # See `Athena::Routing::Exceptions::HTTPException#new`.
  #
  # If *retry_after* is provided, adds a `retry-after` header that represents the number of seconds or HTTP-date after which the request may be retried.
  def initialize(retry_after : Number | String | Nil = nil, message : String? = nil, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    headers.add "retry-after", retry_after.to_s if retry_after

    super :service_unavailable, message, cause, headers
  end
end
