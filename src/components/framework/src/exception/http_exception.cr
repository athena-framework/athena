# :nodoc:
class ::Exception
  def to_json(builder : JSON::Builder) : Nil
    builder.object do
      builder.field "code", 500
      builder.field "message", "Internal Server Error"
    end
  end
end

# Represents an HTTP error.
#
# Each child represents a specific HTTP error with the associated status code.
# Also optionally allows adding headers to the resulting response.
#
# Can be used directly/inherited from to represent non-typical HTTP errors/codes.
class Athena::Framework::Exception::HTTPException < ::Exception
  include Athena::Framework::Exception

  # The `HTTP::Status` associated with `self`.
  getter status : HTTP::Status

  # Any HTTP response headers associated with `self`.
  #
  # Some HTTP errors use response headers to give additional information about `self`.
  property headers : HTTP::Headers

  # Instantiates `self` with the given *status* and *message*.
  #
  # Optionally includes *cause*, and *headers*.
  def initialize(@status : HTTP::Status, message : String, cause : ::Exception? = nil, @headers : HTTP::Headers = HTTP::Headers.new)
    super message, cause
  end

  # Instantiates `self` with the given *status_code* and *message*.
  #
  # Optionally includes *cause*, and *headers*.
  def self.new(status_code : Int32, message : String, cause : ::Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    new HTTP::Status.new(status_code), message, cause, headers
  end

  # Returns the HTTP status code of `#status`.
  def status_code : Int32
    @status.value
  end

  # Serializes `self` to JSON in the format of `{"code":400,"message":"Exception message"}`
  def to_json(builder : JSON::Builder) : Nil
    builder.object do
      builder.field "code", self.status_code
      builder.field "message", @message
    end
  end
end
