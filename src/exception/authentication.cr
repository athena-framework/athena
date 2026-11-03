# The base type of exceptions raised when a user could not be authenticated.
#
# The `#message` of these exceptions may contain sensitive information, such as whether a user exists, so it must not be shown to users.
# Show the `#message_key` instead, optionally interpolating its `#message_data`, e.g. via a translator.
class Athena::Security::Exception::Authentication < RuntimeError
  include Athena::Security::Exception

  # The token of the authentication that failed, if any.
  property token : ASEC::Authentication::Token::Interface? = nil

  # Returns a message describing why the user could not be authenticated, which is safe to show to users.
  def message_key : String
    "An authentication exception occurred."
  end

  # Returns the data to interpolate into the `#message_key`.
  def message_data : Hash(String, String)
    {} of String => String
  end
end
