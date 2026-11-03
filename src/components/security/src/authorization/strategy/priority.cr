# Grants or denies the access based on the first voter that does not abstain, so the order of the voters decides which one overrules the others.
#
# If all voters abstained, the decision is *allow_if_all_abstain_decisions*.
class Athena::Security::Authorization::Strategy::Priority
  include Athena::Security::Authorization::Strategy::Interface

  def initialize(@allow_if_all_abstain_decisions : Bool = false); end

  # :inherit:
  def decide(results : Iterator(ASEC::Authorization::Voter::Access), access_decision : ASEC::Authorization::AccessDecision? = nil) : Bool
    results.each do |result|
      return true if result.granted?
      return false if result.denied?
    end

    @allow_if_all_abstain_decisions
  end

  # :inherit:
  def to_s(io : IO) : Nil
    io << "priority"
  end
end
