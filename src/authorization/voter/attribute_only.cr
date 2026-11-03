# Implemented by voters that vote on attributes alone, whatever the subject, e.g. `ASEC::Authorization::Voter::Role`.
module Athena::Security::Authorization::Voter::AttributeOnly
  # Returns the vote of this voter on whether the provided *token* is granted the provided *attribute*.
  #
  # The vote may be explained by adding reasons to the provided *vote*.
  abstract def vote(token : ASEC::Authentication::Token::Interface, attribute : String, vote : ASEC::Authorization::Voter::Vote? = nil) : ASEC::Authorization::Voter::Access
end
