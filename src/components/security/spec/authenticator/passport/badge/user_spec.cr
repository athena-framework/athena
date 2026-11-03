require "../../../spec_helper"

struct UserBadgeTest < ASPEC::TestCase
  def test_user : Nil
    user = TestUser.new
    identifiers = [] of String

    badge = ASEC::Authenticator::Passport::Badge::User.new("user") { |identifier| identifiers << identifier; user }

    badge.user_identifier.should eq "user"
    badge.user.should be user
    badge.user.should be user
    identifiers.should eq ["user"]
    badge.resolved?.should be_true
  end

  def test_user_loader_proc : Nil
    user = TestUser.new

    ASEC::Authenticator::Passport::Badge::User.new("user", ->(_identifier : String) { user.as ASEC::User::Interface? }).user.should be user
  end

  def test_user_not_found : Nil
    badge = ASEC::Authenticator::Passport::Badge::User.new("dummy") { nil }

    ex = expect_raises ASEC::Exception::UserNotFound do
      badge.user
    end

    ex.user_identifier.should eq "dummy"
  end

  def test_user_without_user_loader : Nil
    expect_raises ASEC::Exception::Logic, "No user loader is configured, did you forget to register the 'ASEC::Listeners::UserProvider' listener?" do
      ASEC::Authenticator::Passport::Badge::User.new("user").user
    end
  end

  def test_empty_user_identifier : Nil
    expect_raises ASEC::Exception::BadCredentials, "Empty user identifier." do
      ASEC::Authenticator::Passport::Badge::User.new ""
    end
  end

  def test_user_identifier_too_long : Nil
    ASEC::Authenticator::Passport::Badge::User.new("a" * ASEC::Authenticator::Passport::Badge::User::MAX_USERNAME_LENGTH).user_identifier.size.should eq 4096

    expect_raises ASEC::Exception::BadCredentials, "Username too long." do
      ASEC::Authenticator::Passport::Badge::User.new "a" * (ASEC::Authenticator::Passport::Badge::User::MAX_USERNAME_LENGTH + 1)
    end
  end

  def test_user_provider : Nil
    user = TestUser.new "wouter"
    provider = MockUserProvider.new load_result: user
    badge = ASEC::Authenticator::Passport::Badge::User.new "wouter"

    badge.user_provider = provider

    badge.user_provider.should be provider
    badge.user_loader.should_not be_nil
    badge.user.should be user
    provider.calls.should eq [{"load_user_by_identifier", "wouter"}]
  end

  def test_user_loader_resets_the_user_provider : Nil
    user = TestUser.new
    badge = ASEC::Authenticator::Passport::Badge::User.new "user"

    badge.user_provider = MockUserProvider.new
    badge.user_loader = ->(_identifier : String) { user.as ASEC::User::Interface? }

    badge.user_provider.should be_nil
    badge.user.should be user
  end
end
