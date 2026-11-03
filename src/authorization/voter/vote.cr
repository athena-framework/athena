# The vote of a voter, which may be explained by reasons.
class Athena::Security::Authorization::Voter::Vote
  # The name of the type of the voter that voted.
  property voter : String = ""

  # The vote of the voter.
  property result : ASEC::Authorization::Voter::Access = :abstain

  # The reasons explaining the vote.
  getter reasons : Array(String) = [] of String

  # Adds the provided *reason* explaining the vote.
  def add_reason(reason : String) : Nil
    @reasons << reason
  end
end
