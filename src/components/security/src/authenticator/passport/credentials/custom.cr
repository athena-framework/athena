# Credentials checked by a block, e.g. comparing an API token presented by the user with the one of the user.
#
# ```
# ASEC::Authenticator::Passport::Credentials::Custom.new(api_token) do |token, user|
#   user.as(User).api_token == token
# end
# ```
class Athena::Security::Authenticator::Passport::Credentials::Custom
  include Athena::Security::Authenticator::Passport::Credentials::Interface

  # :inherit:
  getter? resolved : Bool = false

  # Creates credentials made of the provided *credentials*, which the block checks against the user being authenticated.
  #
  # The authentication fails unless the block returns `true`.
  # The block may also raise an `ASEC::Exception::Authentication` to fail with a more specific reason.
  def self.new(credentials : T, &checker : T, ASEC::User::Interface -> Bool) : self forall T
    new ->(user : ASEC::User::Interface) { checker.call credentials, user }
  end

  private def initialize(@checker : Proc(ASEC::User::Interface, Bool)); end

  # Checks the credentials against the provided *user*, marking them as resolved if they are valid.
  #
  # Raises an `ASEC::Exception::BadCredentials` if the block did not return `true`.
  def execute_custom_checker(user : ASEC::User::Interface) : Nil
    unless @checker.call user
      raise ASEC::Exception::BadCredentials.new "Credentials check failed as the block passed to 'ASEC::Authenticator::Passport::Credentials::Custom' did not return 'true'."
    end

    @resolved = true
  end
end
