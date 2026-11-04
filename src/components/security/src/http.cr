require "log"

require "athena-http_kernel"

require "./athena-security"

# Types nesting others are required first, so that they aren't defined as modules by the nested types.
require "./authenticator/passport"
require "./firewall"

require "./authenticator/passport/badge/interface"
require "./authenticator/passport/badge/*"
require "./authenticator/passport/credentials/interface"
require "./authenticator/passport/credentials/*"
require "./authenticator/passport/self_validating"
require "./authenticator/token/post_authentication"
require "./authenticator/interface"
require "./authenticator/abstract_authenticator"

require "./authentication/expose_security_level"
require "./authentication/authenticator_manager"

require "./entry_point/interface"

require "./events/*"

require "./listeners/*"

require "./firewall/listener_interface"
require "./firewall/*"
require "./firewall_map_interface"
require "./firewall_map"
require "./access_map"

module Athena::Security
  Log = ::Log.for "athena.security"

  # Types related to authenticating requests, such as the passports their users are authenticated with.
  module Authenticator; end

  # Types starting the authentication of users that must authenticate to access a resource, e.g. by redirecting to the login page.
  module EntryPoint; end

  # The `ACTR::EventDispatcher::Event`s emitted while authenticating users.
  module Events; end

  # The event listeners checking the passports of users being authenticated, and acting on their authentication.
  module Listeners; end
end
