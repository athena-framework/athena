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

  # Helper method to return the proper exception subclass for the provided *status*.
  # The *message*, *cause*, and *headers* are passed along as well if provided.
  #
  # ameba:disable Metrics/CyclomaticComplexity
  def self.from_status(
    status : Int32 | HTTP::Status,
    message : String = "",
    cause : ::Exception? = nil,
    headers : HTTP::Headers = HTTP::Headers.new,
  ) : self
    status = status.is_a?(HTTP::Status) ? status : HTTP::Status.new(status)

    case status
    when .bad_request?            then ATH::Exception::BadRequest.new(message, cause, headers)
    when .forbidden?              then ATH::Exception::Forbidden.new(message, cause, headers)
    when .not_found?              then ATH::Exception::NotFound.new(message, cause, headers)
    when .not_acceptable?         then ATH::Exception::NotAcceptable.new(message, cause, headers)
    when .conflict?               then ATH::Exception::Conflict.new(message, cause, headers)
    when .gone?                   then ATH::Exception::Gone.new(message, cause, headers)
    when .length_required?        then ATH::Exception::LengthRequired.new(message, cause, headers)
    when .precondition_failed?    then ATH::Exception::PreconditionFailed.new(message, cause, headers)
    when .unsupported_media_type? then ATH::Exception::UnsupportedMediaType.new(message, cause, headers)
    when .unprocessable_entity?   then ATH::Exception::UnprocessableEntity.new(message, cause, headers)
    when .too_many_requests?      then ATH::Exception::TooManyRequests.new(message, nil, cause, headers)
    when .service_unavailable?    then ATH::Exception::ServiceUnavailable.new(message, nil, cause, headers)
    else
      new status, message, cause, headers
    end
  end

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
