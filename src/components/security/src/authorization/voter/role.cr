# Votes on attributes starting with a prefix, `ROLE_` by default, granting the access if the token has that role.
class Athena::Security::Authorization::Voter::Role < Athena::Security::Authorization::Voter
  include Athena::Security::Authorization::Voter::AttributeOnly

  def initialize(@prefix : String = "ROLE_"); end

  # :inherit:
  def vote(token : ASEC::Authentication::Token::Interface, attribute : String, vote : ASEC::Authorization::Voter::Vote? = nil) : ASEC::Authorization::Voter::Access
    return ASEC::Authorization::Voter::Access::Abstain unless attribute.starts_with? @prefix

    if self.extract_roles(token).includes? attribute
      vote.try &.add_reason "The user has #{attribute}."

      return ASEC::Authorization::Voter::Access::Granted
    end

    vote.try &.add_reason "The user doesn't have #{attribute}."

    ASEC::Authorization::Voter::Access::Denied
  end

  # :inherit:
  def supports_attribute?(attribute : String) : Bool
    attribute.starts_with? @prefix
  end

  # Returns the roles of the provided *token*.
  protected def extract_roles(token : ASEC::Authentication::Token::Interface) : Array(String)
    token.role_names
  end
end
