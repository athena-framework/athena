# Authenticates the requests it supports, e.g. via the credentials of a login form, or an API token.
#
# An authenticator creates an `ASEC::Authenticator::Passport` from the request, which the listeners of the `ASEC::Events::CheckPassport` event check.
# It then creates the token of the authenticated user, see `ASEC::Authentication::AuthenticatorManager`.
#
# ```
# class APITokenAuthenticator < ASEC::Authenticator::AbstractAuthenticator
#   def supports?(request : AHTTP::Request) : Bool?
#     request.headers.has_key? "x-api-token"
#   end
#
#   def authenticate(request : AHTTP::Request) : ASEC::Authenticator::Passport
#     api_token = request.headers["x-api-token"]
#
#     ASEC::Authenticator::Passport::SelfValidating.new(
#       ASEC::Authenticator::Passport::Badge::User.new(api_token) { |token| User.find_by_api_token token }
#     )
#   end
#
#   def on_authentication_success(request : AHTTP::Request, token : ASEC::Authentication::Token::Interface, firewall_name : String) : AHTTP::Response?
#     # Let the request continue.
#     nil
#   end
#
#   def on_authentication_failure(request : AHTTP::Request, exception : ASEC::Exception::Authentication) : AHTTP::Response?
#     AHTTP::Response.new exception.message_key, :unauthorized
#   end
# end
# ```
module Athena::Security::Authenticator::Interface
  # Returns `true` if this authenticator supports the provided *request*, or `false` if it should be skipped.
  #
  # Returning `nil` also means that it supports the *request*, but that it does not need to authenticate it before the token of the user is accessed.
  abstract def supports?(request : AHTTP::Request) : Bool?

  # Returns the passport of the user authenticating via the provided *request*, e.g. with its identifier and password.
  #
  # Raises an `ASEC::Exception::Authentication` if the *request* cannot be authenticated, e.g. because it lacks credentials.
  abstract def authenticate(request : AHTTP::Request) : ASEC::Authenticator::Passport

  # Returns the token of the user authenticated with the provided *passport*, on the firewall with the provided *firewall_name*.
  abstract def create_token(passport : ASEC::Authenticator::Passport, firewall_name : String) : ASEC::Authentication::Token::Interface

  # Returns the response to send once the user was authenticated with the provided *token*, on the firewall with the provided *firewall_name*, e.g. a redirect to the page it visited last.
  #
  # Returning `nil` lets the request continue, e.g. for an API.
  abstract def on_authentication_success(request : AHTTP::Request, token : ASEC::Authentication::Token::Interface, firewall_name : String) : AHTTP::Response?

  # Returns the response to send when the provided *exception* prevented authenticating the user, e.g. because of a wrong password.
  #
  # Returning `nil` lets the request continue without an authenticated user.
  abstract def on_authentication_failure(request : AHTTP::Request, exception : ASEC::Exception::Authentication) : AHTTP::Response?
end
