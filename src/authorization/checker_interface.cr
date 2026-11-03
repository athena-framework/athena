# Checks whether the current user is granted an attribute, such as a role, optionally on a subject.
module Athena::Security::Authorization::CheckerInterface
  # Returns `true` if the current user is granted the provided *attribute*, optionally on the provided *subject*, otherwise `false`.
  #
  # The decision and the votes it was based on are stored in the provided *access_decision*, if any.
  abstract def granted?(attribute : String, subject = nil, access_decision : ASEC::Authorization::AccessDecision? = nil) : Bool
end
