# Represents an invalid `ANG::AcceptLanguage` header.
class Athena::Negotiation::Exception::InvalidLanguage < RuntimeError
  include Athena::Negotiation::Exception

  # Returns the invalid language code.
  getter language : String

  def initialize(@language : String, cause : Exception? = nil)
    super "Invalid language: '#{@language}'.", cause
  end
end
