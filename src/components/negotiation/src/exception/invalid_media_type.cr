# Represents an invalid `ANG::Accept` header.
class Athena::Negotiation::Exception::InvalidMediaType < RuntimeError
  include Athena::Negotiation::Exception

  # Returns the invalid media range.
  getter media_range : String

  def initialize(@media_range : String, cause : Exception? = nil)
    super "Invalid media type: '#{@media_range}'.", cause
  end
end
