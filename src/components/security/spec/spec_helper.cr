require "spec"

require "athena-spec"

require "../src/athena-security"

class TestUser
  include ASEC::User::Interface

  getter user_identifier : String
  getter roles : Array(String)

  def initialize(@user_identifier : String = "user", @roles : Array(String) = ["ROLE_USER"]); end
end

class TestPasswordAuthenticatedUser < TestUser
  include APH::PasswordAuthenticatedUserInterface

  property password : String? = nil
end

class TestToken < ASEC::Authentication::Token::AbstractToken
  def initialize(roles : Array(String) = [] of String, user : ASEC::User::Interface? = nil)
    super roles

    user.try { |u| self.user = u }
  end
end

# Returns or raises the provided results, while recording the calls made to it.
class MockUserProvider
  include ASEC::User::Provider::Interface
  include ASEC::User::PasswordUpgraderInterface

  getter calls = [] of {String, String}

  def initialize(
    @load_result : ASEC::User::Interface | ::Exception = ASEC::Exception::UserNotFound.new("Not found."),
    @refresh_result : ASEC::User::Interface | ::Exception = ASEC::Exception::UnsupportedUser.new("Unsupported."),
    @supports : Bool = true,
    @upgrade_exception : ::Exception? = nil,
  ); end

  def load_user_by_identifier(identifier : String) : ASEC::User::Interface
    @calls << {"load_user_by_identifier", identifier}

    self.result @load_result
  end

  def refresh_user(user : ASEC::User::Interface) : ASEC::User::Interface
    @calls << {"refresh_user", user.user_identifier}

    self.result @refresh_result
  end

  def supports_class?(klass : ASEC::User::Interface.class) : Bool
    @calls << {"supports_class?", klass.to_s}

    @supports
  end

  def upgrade_password(user : APH::PasswordAuthenticatedUserInterface, new_hashed_password : String) : Nil
    @calls << {"upgrade_password", new_hashed_password}

    @upgrade_exception.try { |ex| raise ex }
  end

  private def result(result : ASEC::User::Interface | ::Exception) : ASEC::User::Interface
    raise result if result.is_a? ::Exception

    result
  end
end

class MockUserProviderWithoutUpgrade
  include ASEC::User::Provider::Interface

  def load_user_by_identifier(identifier : String) : ASEC::User::Interface
    raise ASEC::Exception::UserNotFound.new "Not found."
  end

  def refresh_user(user : ASEC::User::Interface) : ASEC::User::Interface
    raise ASEC::Exception::UnsupportedUser.new "Unsupported."
  end

  def supports_class?(klass : ASEC::User::Interface.class) : Bool
    false
  end
end

# Records the calls made to it, raising the provided *exception* if any.
class MockUserChecker
  include ASEC::User::Checker::Interface

  getter calls = [] of {String, ASEC::Authentication::Token::Interface?}

  def initialize(@exception : ::Exception? = nil); end

  def check_pre_auth(user : ASEC::User::Interface) : Nil
    @calls << {"check_pre_auth", nil}

    @exception.try { |ex| raise ex }
  end

  def check_post_auth(user : ASEC::User::Interface, token : ASEC::Authentication::Token::Interface? = nil) : Nil
    @calls << {"check_post_auth", token}

    @exception.try { |ex| raise ex }
  end
end

module Ownable
  abstract def author : String
end

class Post
  include Ownable

  getter author : String
  getter? published : Bool

  def initialize(@author : String = "author", @published : Bool = false); end
end

class DraftPost < Post; end

class Comment
  include Ownable

  getter author : String

  def initialize(@author : String = "author"); end
end

module Archivable
  include Ownable
end

class Article
  include Archivable

  getter author : String

  def initialize(@author : String = "author"); end
end

# Votes the provided *result* on the attributes it supports, while recording the calls made to it.
class MockAttributeVoter < ASEC::Authorization::Voter
  include ASEC::Authorization::Voter::AttributeOnly

  getter calls = [] of {ASEC::Authentication::Token::Interface, String}
  getter supports_attribute_calls = [] of String

  def initialize(
    @result : ASEC::Authorization::Voter::Access = :granted,
    @supported_attributes : Array(String)? = nil,
    @reason : String? = nil,
  ); end

  def vote(token : ASEC::Authentication::Token::Interface, attribute : String, vote : ASEC::Authorization::Voter::Vote? = nil) : ASEC::Authorization::Voter::Access
    @calls << {token, attribute}

    @reason.try { |reason| vote.try &.add_reason reason }

    @result
  end

  def supports_attribute?(attribute : String) : Bool
    @supports_attribute_calls << attribute

    @supported_attributes.try(&.includes?(attribute)) || @supported_attributes.nil?
  end
end

# Grants viewing published posts, and editing posts to their author.
class PostVoter < ASEC::Authorization::Voter
  include ASEC::Authorization::Voter::Subject(Post)

  getter calls = [] of String

  protected def supports?(attribute : String, subject : Post) : Bool
    attribute.in? "VIEW", "EDIT"
  end

  protected def vote_on_attribute(attribute : String, subject : Post, token : ASEC::Authentication::Token::Interface, vote : ASEC::Authorization::Voter::Vote?) : Bool
    @calls << subject.class.name

    if attribute == "VIEW" && subject.published?
      vote.try &.add_reason "The post is published."

      return true
    end

    subject.author == token.user_identifier
  end
end

# Like `PostVoter`, but also grants editing comments to their author.
class PostAndCommentVoter < PostVoter
  include ASEC::Authorization::Voter::Subject(Comment)

  protected def supports?(attribute : String, subject : Comment) : Bool
    attribute == "EDIT"
  end

  protected def vote_on_attribute(attribute : String, subject : Comment, token : ASEC::Authentication::Token::Interface, vote : ASEC::Authorization::Voter::Vote?) : Bool
    @calls << subject.class.name

    subject.author == token.user_identifier
  end
end

# Grants deleting anything `Ownable` to its author.
class OwnableVoter < ASEC::Authorization::Voter
  include ASEC::Authorization::Voter::Subject(Ownable)

  getter calls = [] of String

  protected def supports?(attribute : String, subject : Ownable) : Bool
    attribute == "DELETE"
  end

  protected def vote_on_attribute(attribute : String, subject : Ownable, token : ASEC::Authentication::Token::Interface, vote : ASEC::Authorization::Voter::Vote?) : Bool
    @calls << subject.class.name

    subject.author == token.user_identifier
  end
end

# Grants archiving anything `Archivable` to its author.
class ArchivableVoter < ASEC::Authorization::Voter
  include ASEC::Authorization::Voter::Subject(Archivable)

  getter calls = [] of String

  protected def supports?(attribute : String, subject : Archivable) : Bool
    attribute == "ARCHIVE"
  end

  protected def vote_on_attribute(attribute : String, subject : Archivable, token : ASEC::Authentication::Token::Interface, vote : ASEC::Authorization::Voter::Vote?) : Bool
    @calls << subject.class.name

    subject.author == token.user_identifier
  end
end

# Grants or denies the access based on a `String` subject.
class StringVoter < ASEC::Authorization::Voter
  include ASEC::Authorization::Voter::Subject(String)

  protected def supports?(attribute : String, subject : String) : Bool
    attribute == "MATCH"
  end

  protected def vote_on_attribute(attribute : String, subject : String, token : ASEC::Authentication::Token::Interface, vote : ASEC::Authorization::Voter::Vote?) : Bool
    subject == token.user_identifier
  end
end

# Returns the votes of the voters in a `ASEC::Authorization::AccessDecisionManager` test, from the provided amounts of each vote.
def access_decision_voters(grants : Int32, denies : Int32, abstains : Int32) : Array(ASEC::Authorization::Voter)
  voters = [] of ASEC::Authorization::Voter

  grants.times { voters << MockAttributeVoter.new :granted }
  denies.times { voters << MockAttributeVoter.new :denied }
  abstains.times { voters << MockAttributeVoter.new :abstain }

  voters
end

ASPEC.run_all
