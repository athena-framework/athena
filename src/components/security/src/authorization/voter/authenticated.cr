# Votes on attributes describing how the user authenticated:
#
# * `IS_AUTHENTICATED_FULLY` - Granted if the user is fully authenticated, see `ASEC::Authentication::TrustResolverInterface#full_fledged?`
# * `IS_AUTHENTICATED` - Granted if there is an authenticated user
# * `PUBLIC_ACCESS` - Always granted
class Athena::Security::Authorization::Voter::Authenticated < Athena::Security::Authorization::Voter
  include Athena::Security::Authorization::Voter::AttributeOnly

  IS_AUTHENTICATED_FULLY = "IS_AUTHENTICATED_FULLY"
  IS_AUTHENTICATED       = "IS_AUTHENTICATED"
  PUBLIC_ACCESS          = "PUBLIC_ACCESS"

  def initialize(@authentication_trust_resolver : ASEC::Authentication::TrustResolverInterface); end

  # :inherit:
  def vote(token : ASEC::Authentication::Token::Interface, attribute : String, vote : ASEC::Authorization::Voter::Vote? = nil) : ASEC::Authorization::Voter::Access
    case attribute
    when PUBLIC_ACCESS
      vote.try &.add_reason "Access is public."

      ASEC::Authorization::Voter::Access::Granted
    when IS_AUTHENTICATED_FULLY
      if @authentication_trust_resolver.full_fledged? token
        vote.try &.add_reason "The user is fully authenticated."

        return ASEC::Authorization::Voter::Access::Granted
      end

      vote.try &.add_reason "The user is not fully authenticated."

      ASEC::Authorization::Voter::Access::Denied
    when IS_AUTHENTICATED
      if @authentication_trust_resolver.authenticated? token
        vote.try &.add_reason "The user is authenticated."

        return ASEC::Authorization::Voter::Access::Granted
      end

      vote.try &.add_reason "The user is not authenticated."

      ASEC::Authorization::Voter::Access::Denied
    else
      ASEC::Authorization::Voter::Access::Abstain
    end
  end

  # :inherit:
  def supports_attribute?(attribute : String) : Bool
    attribute.in? IS_AUTHENTICATED_FULLY, IS_AUTHENTICATED, PUBLIC_ACCESS
  end
end
