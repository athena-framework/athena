# Checks whether the current user is granted an attribute, such as a role, optionally on a subject.
module Athena::Security::Authorization::CheckerInterface
  # Returns `true` if the current user is granted the provided *attribute*, optionally on the provided *subject*, otherwise `false`.
  #
  # The decision and the votes it was based on are stored in the provided *access_decision*, if any.
  abstract def granted?(attribute : String, subject = nil, access_decision : ASEC::Authorization::AccessDecision? = nil) : Bool

  # Returns `true` if the current user is granted the provided *attribute*, a member of the attribute enum of a voter, optionally on the provided *subject*, otherwise `false`.
  #
  # The *attribute* is decided as its `ASEC::Authorization::Voter.attribute_name`, see `ASEC::Authorization::Voter::Subject(T, A)`.
  def granted?(attribute : Enum, subject = nil, access_decision : ASEC::Authorization::AccessDecision? = nil) : Bool
    self.granted? ASEC::Authorization::Voter.attribute_name(attribute), subject, access_decision
  end
end
