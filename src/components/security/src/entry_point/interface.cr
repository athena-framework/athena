# Starts the authentication of a user, e.g. by redirecting to the login page, when it accesses a resource that requires an authenticated user.
#
# An authenticator may also be the entry point of its firewall, e.g. an HTTP basic authenticator asking for credentials.
#
# ```
# class LoginEntryPoint
#   include ASEC::EntryPoint::Interface
#
#   def start(request : AHTTP::Request, exception : ASEC::Exception::Authentication? = nil) : AHTTP::Response
#     AHTTP::RedirectResponse.new "/login"
#   end
# end
# ```
module Athena::Security::EntryPoint::Interface
  # Returns a response directing the user to authenticate, e.g. a redirect to the login page.
  #
  # The *exception* explains why the user must authenticate, if any.
  abstract def start(request : AHTTP::Request, exception : ASEC::Exception::Authentication? = nil) : AHTTP::Response
end
