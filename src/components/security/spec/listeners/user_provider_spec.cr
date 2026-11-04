require "../spec_helper"

struct UserProviderListenerTest < ASPEC::TestCase
  @user_provider : ASEC::User::Provider::InMemory
  @listener : ASEC::Listeners::UserProvider

  def initialize
    @user_provider = ASEC::User::Provider::InMemory.new
    @listener = ASEC::Listeners::UserProvider.new @user_provider
  end

  def test_set_user_provider : Nil
    passport = ASEC::Authenticator::Passport::SelfValidating.new ASEC::Authenticator::Passport::Badge::User.new("wouter")

    @listener.check_passport ASEC::Events::CheckPassport.new(MockAuthenticator.new, passport)

    user = ASEC::User::InMemory.new "wouter", nil
    @user_provider.create_user user

    user.equal_to?(passport.user).should be_true
    passport.badge(ASEC::Authenticator::Passport::Badge::User).try(&.user_provider).should be @user_provider
  end

  def test_not_override_user_loader : Nil
    user = TestUser.new
    passport = ASEC::Authenticator::Passport::SelfValidating.new ASEC::Authenticator::Passport::Badge::User.new("wouter") { user }

    @listener.check_passport ASEC::Events::CheckPassport.new(MockAuthenticator.new, passport)

    passport.badge(ASEC::Authenticator::Passport::Badge::User).try(&.user_provider).should be_nil
    passport.user.should be user
  end
end
