# Implemented by voters that vote on subjects of type `T`, see `ASEC::Authorization::Voter`.
#
# The voter abstains unless it `#supports?` the attribute and subject, otherwise it grants the access if `#vote_on_attribute` returns `true`, and denies it if not.
module Athena::Security::Authorization::Voter::Subject(T)
  # Returns the vote of this voter on whether the provided *token* is granted the provided *attribute* on the provided *subject*.
  #
  # The vote may be explained by adding reasons to the provided *vote*.
  def vote(token : ASEC::Authentication::Token::Interface, subject : T, attribute : String, vote : ASEC::Authorization::Voter::Vote? = nil) : ASEC::Authorization::Voter::Access
    return ASEC::Authorization::Voter::Access::Abstain unless self.supports? attribute, subject

    # As soon as the attribute is supported, the access is denied by default.
    vote.try &.result = ASEC::Authorization::Voter::Access::Denied

    result = self.vote_on_attribute(attribute, subject, token, vote) ? ASEC::Authorization::Voter::Access::Granted : ASEC::Authorization::Voter::Access::Denied

    vote.try &.result = result

    result
  end

  # Returns `true` if this voter votes on the provided *attribute* for the provided *subject*, otherwise `false`.
  protected abstract def supports?(attribute : String, subject : T) : Bool

  # Returns `true` if the provided *token* is granted the provided *attribute* on the provided *subject*, otherwise `false`.
  #
  # Only called if this voter `#supports?` the *attribute* and *subject*.
  # The decision may be explained by adding reasons to the provided *vote*.
  protected abstract def vote_on_attribute(attribute : String, subject : T, token : ASEC::Authentication::Token::Interface, vote : ASEC::Authorization::Voter::Vote?) : Bool
end
