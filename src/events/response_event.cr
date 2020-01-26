# Emitted after the route's action has been executed, but before the response has been written in order to allow setting additional headers.
# See [HTTP::Server::Response](https://crystal-lang.org/api/HTTP/Server/Response.html#overview).
# ```
# The response `#status` and `#headers` must be configured before writing the response body. Once response output is written, changing the `#status` and `#headers` properties has no effect.
# ```
#
# This event can be listened on to modify the response object further before it is returned; such as adding headers/cookies etc.
class Athena::Routing::Events::Response < AED::Event
  include Athena::Routing::Events::Context
end
