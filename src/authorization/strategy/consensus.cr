# Grants the access if more voters grant it than deny it, ignoring those that abstain.
#
# If as many voters grant as deny the access, the decision is *allow_if_equal_granted_denied_decisions*.
# If all voters abstained, the decision is *allow_if_all_abstain_decisions*.
class Athena::Security::Authorization::Strategy::Consensus
  include Athena::Security::Authorization::Strategy::Interface

  def initialize(
    @allow_if_all_abstain_decisions : Bool = false,
    @allow_if_equal_granted_denied_decisions : Bool = true,
  ); end

  # :inherit:
  def decide(results : Iterator(ASEC::Authorization::Voter::Access), access_decision : ASEC::Authorization::AccessDecision? = nil) : Bool
    grant = 0
    deny = 0

    results.each do |result|
      if result.granted?
        grant += 1
      elsif result.denied?
        deny += 1
      end
    end

    return true if grant > deny
    return false if deny > grant
    return @allow_if_equal_granted_denied_decisions if grant > 0

    @allow_if_all_abstain_decisions
  end

  # :inherit:
  def to_s(io : IO) : Nil
    io << "consensus"
  end
end
