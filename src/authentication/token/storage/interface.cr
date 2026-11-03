class Athena::Security::Authentication::Token::Storage; end

# Holds the token of the current user.
module Athena::Security::Authentication::Token::Storage::Interface
  # Returns the token of the current user, if any.
  abstract def token : ASEC::Authentication::Token::Interface?

  # Sets the token of the current user, or removes it if *token* is `nil`.
  abstract def token=(token : ASEC::Authentication::Token::Interface?)
end
