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
# The component has no dependencies and is framework agnostic; supporting various negotiators.
#
# ## Getting Started
#
# If using this component within the [Athena Framework][Athena::Framework], it is already installed and required for you.
# Checkout the [manual](../architecture/negotiation.md) for some additional information on how to use it within the framework.
#
# If using it outside of the framework, you will first need to add it as a dependency:
#
# ```yaml
# dependencies:
#   athena-negotiation:
#     github: athena-framework/negotiation
#     version: ~> 0.1.0
# ```
#
# Then run `shards install`, being sure to require it via `require "athena-negotiation"`.
#
# ## Usage
#
# The main type of `Athena::Negotiation` is `ANG::AbstractNegotiator` which is used to implement negotiators for each `Accept*` header.
# `Athena::Negotiation` exposes class level getters for each negotiator; that return a lazily initialized singleton instance.
# Each negotiator exposes two methods: `ANG::AbstractNegotiator#best` and `ANG::AbstractNegotiator#ordered_elements`.
#
# ### Media Type
#
# ```
# negotiator = ANG.negotiator
#
# accept_header = "text/html, application/xhtml+xml, application/xml;q=0.9"
# priorities = ["text/html; charset=UTF-8", "application/json", "application/xml;q=0.5"]
#
# accept = negotiator.best(accept_header, priorities).not_nil!
#
# accept.media_range # => "text/html"
# accept.parameters  # => {"charset" => "UTF-8"}
# ```
#
# The `ANG::Negotiator` type returns an `ANG::Accept`, or `nil` if negotiating the best media type has failed.
#
# ### Character Set
#
# ```
# negotiator = ANG.charset_negotiator
#
# accept_header = "ISO-8859-1, UTF-8; q=0.9"
# priorities = ["iso-8859-1;q=0.3", "utf-8;q=0.9", "utf-16;q=1.0"]
#
# accept = negotiator.best(accept_header, priorities).not_nil!
#
# accept.charset # => "utf-8"
# accept.quality # => 0.9
# ```
#
# The `ANG::CharsetNegotiator` type returns an `ANG::AcceptCharset`, or `nil` if negotiating the best character set has failed.
#
# ### Encoding
#
# ```
# negotiator = ANG.encoding_negotiator
#
# accept_header = "gzip;q=1.0, identity; q=0.5, *;q=0"
# priorities = ["gzip", "foo"]
#
# accept = negotiator.best(accept_header, priorities).not_nil!
#
# accept.coding # => "gzip"
# ```
#
# The `ANG::EncodingNegotiator` type returns an `ANG::AcceptEncoding`, or `nil` if negotiating the best encoding has failed.
#
# ### Language
#
# ```
# negotiator = ANG.language_negotiator
#
# accept_header = "en; q=0.1, fr; q=0.4, zh-Hans-CN; q=0.9, de; q=0.2"
# priorities = ["de", "zh-Hans-CN", "en"]
#
# accept = negotiator.best(accept_header, priorities).not_nil!
#
# accept.language # => "zh"
# accept.region   # => "cn"
# accept.script   # => "hans"
# ```
#
# The `ANG::LanguageNegotiator` type returns an `ANG::AcceptLanguage`, or `nil` if negotiating the best language has failed.
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
