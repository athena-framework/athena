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

# The `Athena::Mercure` component allows easily pushing updates to web browsers and other HTTP clients using the [Mercure protocol](https://mercure.rocks/docs/mercure).
# Because it is built on top of [Server-Sent Events (SSE)](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events), Mercure is supported out of the box in modern browsers.
#
# Mercure comes with an authorization mechanism, automatic reconnection in case of network issues with retrieving of lost updates, a presence API, "connection-less" push for smartphones and auto-discoverability (a supported client can automatically discover and subscribe to updates of a given resource thanks to a specific HTTP header).
module Athena::Mercure
  VERSION = "0.1.0"

  # See [AMC::TokenFactory::Interface][]
  module TokenFactory; end

  # See [AMC::TokenProvider::Interface][]
  module TokenProvider; end

  # Both acts as a namespace for exceptions related to the `Athena::Mercure` component, as well as a way to check for exceptions from the component.
  module Exception; end
end
