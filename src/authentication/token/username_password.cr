# Represents a user authenticated on a firewall, typically via a username and password.
class Athena::Security::Authentication::Token::UsernamePassword < Athena::Security::Authentication::Token::AbstractToken
  # Returns the name of the firewall the user authenticated on.
  getter firewall_name : String

  def initialize(user : ASEC::User::Interface, @firewall_name : String, roles : Array(String) = [] of String)
    super roles

    raise ASEC::Exception::InvalidArgument.new "The firewall name must not be empty." if @firewall_name.empty?

    self.user = user
  end
end
