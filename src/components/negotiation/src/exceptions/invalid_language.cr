require "./negotiation_exception"

# Represents an invalid `ANG::AcceptLanguage` header.
class Athena::Negotiation::Exceptions::InvalidLanguage < Athena::Negotiation::Exceptions::Negotiation
  # Returns the invalid language code.
  getter language : String

  def initialize(@language : String, cause : Exception? = nil)
    super "Invalid language: '#{@language}'.", cause
  end
end
