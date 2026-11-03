# Grants the access as soon as a voter grants it.
#
# If all voters abstained, the decision is *allow_if_all_abstain_decisions*.
class Athena::Security::Authorization::Strategy::Affirmative
  include Athena::Security::Authorization::Strategy::Interface

  def initialize(@allow_if_all_abstain_decisions : Bool = false); end

  # :inherit:
  def decide(results : Iterator(ASEC::Authorization::Voter::Access), access_decision : ASEC::Authorization::AccessDecision? = nil) : Bool
    deny = 0

    results.each do |result|
      return true if result.granted?

      deny += 1 if result.denied?
    end

    return false if deny > 0

    @allow_if_all_abstain_decisions
  end

  # :inherit:
  def to_s(io : IO) : Nil
    io << "affirmative"
  end
end
