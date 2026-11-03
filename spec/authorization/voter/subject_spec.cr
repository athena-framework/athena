require "../../spec_helper"

struct SubjectVoterTest < ASPEC::TestCase
  @[DataProvider("vote_tests")]
  def test_vote(attribute : String, subject : Post, expected : ASEC::Authorization::Voter::Access) : Nil
    token = TestToken.new user: TestUser.new("author")

    PostVoter.new.vote(token, subject, attribute).should eq expected

    vote = ASEC::Authorization::Voter::Vote.new
    PostVoter.new.vote(token, subject, attribute, vote).should eq expected
    vote.result.should eq expected
  end

  def vote_tests : Hash
    {
      "granted if the attribute is supported and grants access"        => {"EDIT", Post.new("author"), ASEC::Authorization::Voter::Access::Granted},
      "denied if the attribute is supported and does not grant access" => {"EDIT", Post.new("other"), ASEC::Authorization::Voter::Access::Denied},
      "abstain if the attribute is not supported"                      => {"DELETE", Post.new("author"), ASEC::Authorization::Voter::Access::Abstain},
    }
  end

  def test_vote_reasons : Nil
    vote = ASEC::Authorization::Voter::Vote.new

    PostVoter.new.vote(ASEC::Authentication::Token::Null.new, Post.new(published: true), "VIEW", vote).should eq ASEC::Authorization::Voter::Access::Granted

    vote.reasons.should eq ["The post is published."]
  end

  def test_supports_attribute : Nil
    PostVoter.new.supports_attribute?("anything").should be_true
  end
end
