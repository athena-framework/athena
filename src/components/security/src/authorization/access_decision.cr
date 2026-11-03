# Holds an access decision, along with the votes it was based on.
class Athena::Security::Authorization::AccessDecision
  # The name of the strategy that made the decision.
  property strategy : String? = nil

  # Whether the access was granted.
  property? granted : Bool = false

  # The votes the decision was based on.
  getter votes : Array(ASEC::Authorization::Voter::Vote) = [] of ASEC::Authorization::Voter::Vote

  # Returns a message explaining the decision, made of the reasons of the votes that agree with it.
  def message : String
    access = @granted ? ASEC::Authorization::Voter::Access::Granted : ASEC::Authorization::Voter::Access::Denied

    String.build do |io|
      io << (@granted ? "Access Granted." : "Access Denied.")

      @votes.each do |vote|
        next unless vote.result == access

        vote.reasons.each do |reason|
          io << ' ' << reason
        end
      end
    end
  end
end
