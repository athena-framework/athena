require "jwt"

require "http/client"
require "http/headers"

require "./authorization"
require "./discovery"
require "./update"

require "./exceptions/*"
require "./hub/*"
require "./token_provider/*"
require "./token_factory/*"

# Convenience alias to make referencing `Athena::Mercure` types easier.
alias AMC = Athena::Mercure

module Athena::Mercure
  VERSION = "0.1.0"
end
