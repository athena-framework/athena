require "../spec_helper"

# Asserts that it reads the expected results in order, granting the access on the second one.
class SecondResultGrantsStrategy
  include ASEC::Authorization::Strategy::Interface

  getter results = [] of ASEC::Authorization::Voter::Access

  def decide(results : Iterator(ASEC::Authorization::Voter::Access), access_decision : ASEC::Authorization::AccessDecision? = nil) : Bool
    results.each do |result|
      @results << result

      return true if @results.size == 2
    end

    false
  end

  def to_s(io : IO) : Nil
    io << "second_result_grants"
  end
end

struct AccessDecisionManagerTest < ASPEC::TestCase
  @token : ASEC::Authentication::Token::Interface

  def initialize
    @token = TestToken.new ["ROLE_USER"], TestUser.new("author")
  end

  def test_voters_vote_lazily : Nil
    strategy = SecondResultGrantsStrategy.new
    unexpected_voter = MockAttributeVoter.new
    access_decision = ASEC::Authorization::AccessDecision.new

    manager = ASEC::Authorization::AccessDecisionManager.new [MockAttributeVoter.new(:denied), MockAttributeVoter.new(:granted), unexpected_voter] of ASEC::Authorization::Voter, strategy

    manager.decide(ASEC::Authentication::Token::Null.new, "ROLE_FOO", access_decision: access_decision).should be_true

    strategy.results.should eq [ASEC::Authorization::Voter::Access::Denied, ASEC::Authorization::Voter::Access::Granted]
    unexpected_voter.calls.should be_empty
    access_decision.votes.map(&.result).should eq [ASEC::Authorization::Voter::Access::Denied, ASEC::Authorization::Voter::Access::Granted]
  end

  def test_defaults_to_the_affirmative_strategy : Nil
    access_decision = ASEC::Authorization::AccessDecision.new

    ASEC::Authorization::AccessDecisionManager.new.decide(@token, "ROLE_FOO", access_decision: access_decision).should be_false

    access_decision.strategy.should eq "affirmative"
  end

  def test_supported_attributes_are_cached : Nil
    voter = MockAttributeVoter.new
    manager = ASEC::Authorization::AccessDecisionManager.new [voter] of ASEC::Authorization::Voter

    manager.decide(@token, "foo", "bar").should be_true
    manager.decide(@token, "foo", "bar").should be_true

    voter.supports_attribute_calls.should eq ["foo"]
    voter.calls.should eq [{@token, "foo"}, {@token, "foo"}]
  end

  def test_voters_not_supporting_the_attribute_do_not_vote : Nil
    voter = MockAttributeVoter.new supported_attributes: ["bar"]
    access_decision = ASEC::Authorization::AccessDecision.new

    ASEC::Authorization::AccessDecisionManager.new([voter] of ASEC::Authorization::Voter).decide(@token, "foo", access_decision: access_decision).should be_false

    voter.calls.should be_empty
    access_decision.votes.should be_empty
  end

  def test_records_the_decision : Nil
    access_decision = ASEC::Authorization::AccessDecision.new
    voters = [
      MockAttributeVoter.new(:abstain),
      MockAttributeVoter.new(:granted, reason: "Because."),
    ] of ASEC::Authorization::Voter

    ASEC::Authorization::AccessDecisionManager.new(voters, ASEC::Authorization::Strategy::Unanimous.new).decide(@token, "foo", access_decision: access_decision).should be_true

    access_decision.granted?.should be_true
    access_decision.strategy.should eq "unanimous"
    access_decision.votes.map { |vote| {vote.voter, vote.result, vote.reasons} }.should eq [
      {"MockAttributeVoter", ASEC::Authorization::Voter::Access::Abstain, [] of String},
      {"MockAttributeVoter", ASEC::Authorization::Voter::Access::Granted, ["Because."]},
    ]
    access_decision.message.should eq "Access Granted. Because."
  end

  def test_subject_voter : Nil
    voter = PostVoter.new
    manager = ASEC::Authorization::AccessDecisionManager.new [voter] of ASEC::Authorization::Voter

    manager.decide(@token, "EDIT", Post.new("author")).should be_true
    manager.decide(@token, "EDIT", Post.new("other")).should be_false
    manager.decide(@token, "VIEW", Post.new("other", published: true)).should be_true

    voter.calls.should eq ["Post", "Post", "Post"]
  end

  def test_subject_voter_unsupported_attribute : Nil
    voter = PostVoter.new
    access_decision = ASEC::Authorization::AccessDecision.new

    ASEC::Authorization::AccessDecisionManager.new([voter] of ASEC::Authorization::Voter).decide(@token, "DELETE", Post.new("author"), access_decision).should be_false

    voter.calls.should be_empty
    access_decision.votes.map(&.result).should eq [ASEC::Authorization::Voter::Access::Abstain]
  end

  def test_subject_voter_subclass_subject : Nil
    voter = PostVoter.new

    ASEC::Authorization::AccessDecisionManager.new([voter] of ASEC::Authorization::Voter).decide(@token, "EDIT", DraftPost.new("author")).should be_true

    voter.calls.should eq ["DraftPost"]
  end

  def test_subject_voter_abstains_on_other_subjects : Nil
    voter = PostVoter.new
    access_decision = ASEC::Authorization::AccessDecision.new
    manager = ASEC::Authorization::AccessDecisionManager.new([voter] of ASEC::Authorization::Voter)

    manager.decide(@token, "EDIT", Comment.new("author"), access_decision).should be_false
    manager.decide(@token, "EDIT", "author").should be_false
    manager.decide(@token, "EDIT").should be_false

    voter.calls.should be_empty
    access_decision.votes.map(&.result).should eq [ASEC::Authorization::Voter::Access::Abstain]
  end

  def test_subject_voter_with_multiple_types : Nil
    voter = PostAndCommentVoter.new
    manager = ASEC::Authorization::AccessDecisionManager.new [voter] of ASEC::Authorization::Voter

    manager.decide(@token, "EDIT", Post.new("author")).should be_true
    manager.decide(@token, "EDIT", Comment.new("author")).should be_true
    manager.decide(@token, "VIEW", Comment.new("author")).should be_false

    voter.calls.should eq ["Post", "Comment"]
  end

  def test_subject_voter_with_union_typed_subject : Nil
    voter = PostAndCommentVoter.new
    manager = ASEC::Authorization::AccessDecisionManager.new [voter] of ASEC::Authorization::Voter

    [Post.new("author"), Comment.new("author")].each do |subject|
      typeof(subject).should eq Post | Comment

      manager.decide(@token, "EDIT", subject).should be_true
    end

    voter.calls.should eq ["Post", "Comment"]
  end

  def test_subject_voter_on_module : Nil
    voter = OwnableVoter.new
    manager = ASEC::Authorization::AccessDecisionManager.new [voter] of ASEC::Authorization::Voter

    manager.decide(@token, "DELETE", Post.new("author")).should be_true
    manager.decide(@token, "DELETE", DraftPost.new("author")).should be_true
    manager.decide(@token, "DELETE", Comment.new("other")).should be_false

    voter.calls.should eq ["Post", "DraftPost", "Comment"]
  end

  def test_subject_typed_as_module : Nil
    voter = PostVoter.new
    ownable_voter = OwnableVoter.new
    manager = ASEC::Authorization::AccessDecisionManager.new [voter, ownable_voter] of ASEC::Authorization::Voter

    subjects = [Post.new("author"), Comment.new("author")] of Ownable

    subjects.map { |subject| manager.decide @token, "EDIT", subject }.should eq [true, false]
    subjects.map { |subject| manager.decide @token, "DELETE", subject }.should eq [true, true]

    voter.calls.should eq ["Post"]
    ownable_voter.calls.should eq ["Post", "Comment"]
  end

  def test_subject_typed_as_module_included_via_another_module : Nil
    voter = ArchivableVoter.new
    manager = ASEC::Authorization::AccessDecisionManager.new [voter] of ASEC::Authorization::Voter

    subjects = [Article.new("author"), Article.new("other"), Post.new("author")] of Ownable

    subjects.map { |subject| manager.decide @token, "ARCHIVE", subject }.should eq [true, false, false]

    voter.calls.should eq ["Article", "Article"]
  end

  def test_subject_voter_on_value_type : Nil
    manager = ASEC::Authorization::AccessDecisionManager.new [StringVoter.new] of ASEC::Authorization::Voter

    manager.decide(@token, "MATCH", "author").should be_true
    manager.decide(@token, "MATCH", "other").should be_false
    manager.decide(@token, "MATCH", 123).should be_false
  end

  def test_attribute_and_subject_voters : Nil
    attribute_voter = MockAttributeVoter.new :denied, supported_attributes: ["EDIT"]
    access_decision = ASEC::Authorization::AccessDecision.new
    manager = ASEC::Authorization::AccessDecisionManager.new [attribute_voter, PostVoter.new] of ASEC::Authorization::Voter

    manager.decide(@token, "EDIT", Post.new("author"), access_decision).should be_true

    attribute_voter.calls.should eq [{@token, "EDIT"}]
    access_decision.votes.map { |vote| {vote.voter, vote.result} }.should eq [
      {"MockAttributeVoter", ASEC::Authorization::Voter::Access::Denied},
      {"PostVoter", ASEC::Authorization::Voter::Access::Granted},
    ]
  end

  def test_nested_decision_shares_the_ongoing_access_decision : Nil
    access_decision = ASEC::Authorization::AccessDecision.new
    manager = uninitialized ASEC::Authorization::AccessDecisionManager
    nested_voter = NestedDecisionVoter.new -> { manager.decide @token, "ROLE_NESTED" }

    manager = ASEC::Authorization::AccessDecisionManager.new [nested_voter, MockAttributeVoter.new(:granted, supported_attributes: ["ROLE_NESTED"])] of ASEC::Authorization::Voter

    manager.decide(@token, "ROLE_FOO", access_decision: access_decision).should be_true

    access_decision.votes.map { |vote| {vote.voter, vote.result} }.should eq [
      {"MockAttributeVoter", ASEC::Authorization::Voter::Access::Granted},
      {"NestedDecisionVoter", ASEC::Authorization::Voter::Access::Granted},
    ]
  end
end

# Votes the decision of the provided *decide* proc, made while voting.
class NestedDecisionVoter < ASEC::Authorization::Voter
  include ASEC::Authorization::Voter::AttributeOnly

  def initialize(@decide : Proc(Bool)); end

  def vote(token : ASEC::Authentication::Token::Interface, attribute : String, vote : ASEC::Authorization::Voter::Vote? = nil) : ASEC::Authorization::Voter::Access
    @decide.call ? ASEC::Authorization::Voter::Access::Granted : ASEC::Authorization::Voter::Access::Denied
  end

  def supports_attribute?(attribute : String) : Bool
    attribute == "ROLE_FOO"
  end
end
