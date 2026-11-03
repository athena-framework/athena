# Turns the votes of the voters into the decision of an `ASEC::Authorization::AccessDecisionManager`.
module Athena::Security::Authorization::Strategy::Interface
  # Returns `true` if the access is granted based on the provided *results*, otherwise `false`.
  #
  # The *results* are lazy: each voter only votes once its result is read, so a strategy can stop reading them as soon as its decision is known.
  abstract def decide(results : Iterator(ASEC::Authorization::Voter::Access), access_decision : ASEC::Authorization::AccessDecision? = nil) : Bool

  # Writes the name of this strategy to the provided *io*.
  abstract def to_s(io : IO) : Nil
end
