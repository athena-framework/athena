# Grants the access if no voter denies it, and at least one grants it.
#
# If all voters abstained, the decision is *allow_if_all_abstain_decisions*.
class Athena::Security::Authorization::Strategy::Unanimous
  include Athena::Security::Authorization::Strategy::Interface

  def initialize(@allow_if_all_abstain_decisions : Bool = false); end

  # :inherit:
  def decide(results : Iterator(ASEC::Authorization::Voter::Access), access_decision : ASEC::Authorization::AccessDecision? = nil) : Bool
    grant = 0

    results.each do |result|
      return false if result.denied?

      grant += 1 if result.granted?
    end

    return true if grant > 0

    @allow_if_all_abstain_decisions
  end

  # :inherit:
  def to_s(io : IO) : Nil
    io << "unanimous"
  end
end
