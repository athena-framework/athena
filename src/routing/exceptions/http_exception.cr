# Represents an HTTP error.
#
# Each child represents a specific HTTP error with the associated status code.
# Also optionally allows adding headers to the resulting response.
#
# Can be used directly/inherited from to represent non-typical HTTP errors/codes.
class Athena::Routing::Exceptions::HTTPException < Exception
  # The `HTTP::Status` associated with `self`.
  getter status : HTTP::Status

  # Any HTTP response headers associated with `self`.
  #
  # Some HTTP errors use response headers to give additional information about `self`.
  property headers : HTTP::Headers

  # Instantiates `self` with the given *status*.
  #
  # Optionally includes *message*, *cause*, and *headers*.
  def initialize(@status : HTTP::Status, message : String? = nil, cause : Exception? = nil, @headers : HTTP::Headers = HTTP::Headers.new)
    super message, cause
  end

  # Instantiates `self` with the given *status_code*.
  #
  # Optionally includes *message*, *cause*, and *headers*.
  def self.new(status_code : Int32, message : String? = nil, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    new HTTP::Status.new(status_code), message, cause, headers
  end

  # Returns the HTTP status code of `#status`.
  def status_code : Int32
    @status.value
  end

  macro inherited
    macro finished
      {% verbatim do %}
        # Define an initializer if the child doesn't implement one on its own
        {% unless @type.class.overrides? Athena::Routing::Exceptions::HTTPException.class, "new" %}
          # See `Athena::Routing::Exceptions::HTTPException#new`.
          def initialize(message : String? = nil, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
            super {{@type.name.split("::").last.underscore.id.symbolize}}, message, cause, headers
          end
        {% end %}
      {% end %}
    end
  end
end
