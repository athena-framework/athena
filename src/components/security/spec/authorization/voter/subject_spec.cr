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

  @[DataProvider("enum_vote_tests")]
  def test_vote_with_an_attribute_enum(attribute : String, subject : Post, expected : ASEC::Authorization::Voter::Access) : Nil
    voter = EnumPostVoter.new
    vote = ASEC::Authorization::Voter::Vote.new

    voter.vote(TestToken.new(user: TestUser.new("author")), subject, attribute, vote).should eq expected
    vote.result.should eq expected
  end

  def enum_vote_tests : Hash
    {
      "granted if the member grants access"        => {"EnumPostVoter::Attribute::Edit", Post.new("author"), ASEC::Authorization::Voter::Access::Granted},
      "denied if the member does not grant access" => {"EnumPostVoter::Attribute::Edit", Post.new("other"), ASEC::Authorization::Voter::Access::Denied},
      "abstain if not a member"                    => {"EnumPostVoter::Attribute::Delete", Post.new("author"), ASEC::Authorization::Voter::Access::Abstain},
      "abstain if only the name of a member"       => {"Edit", Post.new("author"), ASEC::Authorization::Voter::Access::Abstain},
      "abstain if a member of another enum"        => {"EnumPostAndCommentVoter::CommentAttribute::Edit", Post.new("author"), ASEC::Authorization::Voter::Access::Abstain},
      "abstain if a string attribute"              => {"EDIT", Post.new("author"), ASEC::Authorization::Voter::Access::Abstain},
    }
  end

  def test_vote_with_an_attribute_enum_receives_the_member : Nil
    voter = EnumPostVoter.new

    voter.vote TestToken.new(user: TestUser.new("author")), Post.new(published: true), "EnumPostVoter::Attribute::View"

    voter.calls.should eq [EnumPostVoter::Attribute::View]
  end

  def test_vote_with_attribute_enums_per_subject_type : Nil
    voter = EnumPostAndCommentVoter.new
    token = TestToken.new user: TestUser.new("author")

    voter.vote(token, Comment.new("author"), "EnumPostAndCommentVoter::CommentAttribute::Delete").should eq ASEC::Authorization::Voter::Access::Granted
    voter.vote(token, Comment.new("author"), "EnumPostVoter::Attribute::Edit").should eq ASEC::Authorization::Voter::Access::Abstain
    voter.vote(token, Post.new("author"), "EnumPostVoter::Attribute::Edit").should eq ASEC::Authorization::Voter::Access::Granted
  end

  def test_supports_attribute_with_an_attribute_enum : Nil
    voter = EnumPostVoter.new

    voter.supports_attribute?("EnumPostVoter::Attribute::View").should be_true
    voter.supports_attribute?("EnumPostVoter::Attribute::Edit").should be_true
    voter.supports_attribute?("EnumPostVoter::Attribute::Delete").should be_false
    voter.supports_attribute?("ROLE_ADMIN").should be_false
  end

  def test_supports_attribute_with_attribute_enums_per_subject_type : Nil
    voter = EnumPostAndCommentVoter.new

    voter.supports_attribute?("EnumPostVoter::Attribute::Edit").should be_true
    voter.supports_attribute?("EnumPostAndCommentVoter::CommentAttribute::Delete").should be_true
    voter.supports_attribute?("ROLE_ADMIN").should be_false
  end

  def test_supports_attribute_with_an_attribute_enum_and_string_attributes : Nil
    EnumPostAndStringCommentVoter.new.supports_attribute?("anything").should be_true
  end

  def test_attribute_name : Nil
    ASEC::Authorization::Voter.attribute_name(EnumPostVoter::Attribute::Edit).should eq "EnumPostVoter::Attribute::Edit"
  end

  def test_parse_attribute : Nil
    ASEC::Authorization::Voter.parse_attribute("EnumPostVoter::Attribute::Edit", EnumPostVoter::Attribute).should eq EnumPostVoter::Attribute::Edit
    ASEC::Authorization::Voter.parse_attribute("EnumPostVoter::Attribute::Delete", EnumPostVoter::Attribute).should be_nil
    ASEC::Authorization::Voter.parse_attribute("Edit", EnumPostVoter::Attribute).should be_nil
  end
end
