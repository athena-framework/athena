require "jwt"

require "http/client"
require "http/headers"

require "./authorization"
require "./discovery"
require "./update"

require "./exception/*"
require "./hub/*"
require "./token_provider/*"
require "./token_factory/*"

# Convenience alias to make referencing `Athena::Mercure` types easier.
alias AMC = Athena::Mercure

module Athena::Mercure
  VERSION = "0.1.0"

  # Both acts as a namespace for exceptions related to the `Athena::Mercure` component, as well as a way to check for exceptions from the component.
  module Exception; end
end
