require "../spec_helper"

struct UserCheckerListenerTest < ASPEC::TestCase
  @user_checker : MockUserChecker
  @listener : ASEC::Listeners::UserChecker
  @user : ASEC::User::InMemory

  def initialize
    @user_checker = MockUserChecker.new
    @listener = ASEC::Listeners::UserChecker.new @user_checker
    @user = ASEC::User::InMemory.new "test", nil
  end

  def test_pre_auth : Nil
    @listener.pre_check_credentials ASEC::Events::CheckPassport.new(MockAuthenticator.new, ASEC::Authenticator::Passport::SelfValidating.new(ASEC::Authenticator::Passport::Badge::User.new("test") { @user }))

    @user_checker.calls.should eq [{"check_pre_auth", nil}]
  end

  def test_post_auth_valid_credentials : Nil
    token = ASEC::Authenticator::Token::PostAuthentication.new @user, "main", [] of String

    @listener.post_check_credentials ASEC::Events::AuthenticationSuccess.new token

    @user_checker.calls.should eq [{"check_post_auth", token}]
  end

  def test_post_auth_without_user : Nil
    @listener.post_check_credentials ASEC::Events::AuthenticationSuccess.new ASEC::Authentication::Token::Null.new

    @user_checker.calls.should be_empty
  end
end
