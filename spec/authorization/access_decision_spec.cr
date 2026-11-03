require "../spec_helper"

struct AccessDecisionTest < ASPEC::TestCase
  def test_message_without_votes : Nil
    access_decision = ASEC::Authorization::AccessDecision.new
    access_decision.message.should eq "Access Denied."

    access_decision.granted = true
    access_decision.message.should eq "Access Granted."
  end

  def test_message_only_includes_the_reasons_of_votes_agreeing_with_the_decision : Nil
    access_decision = ASEC::Authorization::AccessDecision.new
    access_decision.votes << self.vote(:denied, "First denial.", "Second denial.")
    access_decision.votes << self.vote(:granted, "Grant.")
    access_decision.votes << self.vote(:denied, "Third denial.")

    access_decision.message.should eq "Access Denied. First denial. Second denial. Third denial."

    access_decision.granted = true
    access_decision.message.should eq "Access Granted. Grant."
  end

  private def vote(result : ASEC::Authorization::Voter::Access, *reasons : String) : ASEC::Authorization::Voter::Vote
    vote = ASEC::Authorization::Voter::Vote.new
    vote.result = result
    reasons.each { |reason| vote.add_reason reason }

    vote
  end
end
