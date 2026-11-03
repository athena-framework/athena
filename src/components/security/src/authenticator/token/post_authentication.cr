# Represents a user authenticated on a firewall by an `ASEC::Authenticator::Interface`.
#
# It is the token created by `ASEC::Authenticator::AbstractAuthenticator#create_token`.
class Athena::Security::Authenticator::Token::PostAuthentication < Athena::Security::Authentication::Token::AbstractToken
  # Returns the name of the firewall the user authenticated on.
  getter firewall_name : String

  def initialize(user : ASEC::User::Interface, @firewall_name : String, roles : Array(String))
    super roles

    raise ASEC::Exception::InvalidArgument.new "The firewall name must not be empty." if @firewall_name.empty?

    self.user = user
  end
end
