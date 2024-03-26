require "./accept"
require "./accept_match"
require "./accept_charset"
require "./accept_encoding"
require "./accept_language"
require "./charset_negotiator"
require "./encoding_negotiator"
require "./language_negotiator"
require "./negotiator"

require "./exceptions/*"

# Convenience alias to make referencing `Athena::Negotiation` types easier.
alias ANG = Athena::Negotiation

# The `Athena::Negotiation` component allows an application to support [content negotiation](https://tools.ietf.org/html/rfc7231#section-5.3).
module Athena::Negotiation
  VERSION = "0.1.4"

  # Returns a lazily initialized `ANG::Negotiator` singleton instance.
  class_getter(negotiator) { ANG::Negotiator.new }

  # Returns a lazily initialized `ANG::CharsetNegotiator` singleton instance.
  class_getter(charset_negotiator) { ANG::CharsetNegotiator.new }

  # Returns a lazily initialized `ANG::EncodingNegotiator` singleton instance.
  class_getter(encoding_negotiator) { ANG::EncodingNegotiator.new }

  # Returns a lazily initialized `ANG::LanguageNegotiator` singleton instance.
  class_getter(language_negotiator) { ANG::LanguageNegotiator.new }

  # Contains all custom exceptions defined within `Athena::Negotiation`.
  module Exceptions; end
end
