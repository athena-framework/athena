require "../spec_helper"

struct PasswordMigratingListenerTest < ASPEC::TestCase
  @user : ASEC::User::InMemory
  @hasher : MockPasswordHasher
  @listener : ASEC::Listeners::PasswordMigrating

  def initialize
    @user = ASEC::User::InMemory.new "John", "old-hash"
    @hasher = MockPasswordHasher.new needs_rehash: true
    @listener = ASEC::Listeners::PasswordMigrating.new APH::Factory.new({ASEC::User::InMemory => @hasher.as APH::Interface})
  end

  def test_no_password_upgrade_badge : Nil
    hasher_factory = MockPasswordHasherFactory.new

    ASEC::Listeners::PasswordMigrating.new(hasher_factory).on_login_success self.create_event ASEC::Authenticator::Passport::SelfValidating.new(ASEC::Authenticator::Passport::Badge::User.new("test") { @user })

    hasher_factory.calls.should eq 0
  end

  def test_blank_password : Nil
    hasher_factory = MockPasswordHasherFactory.new
    upgrader = MockUserProvider.new

    ASEC::Listeners::PasswordMigrating.new(hasher_factory).on_login_success self.create_event ASEC::Authenticator::Passport::SelfValidating.new(
      ASEC::Authenticator::Passport::Badge::User.new("test") { @user },
      [ASEC::Authenticator::Passport::Badge::PasswordUpgrade.new("", upgrader)],
    )

    hasher_factory.calls.should eq 0
    upgrader.calls.should be_empty
  end

  def test_upgrade_with_upgrader : Nil
    upgrader = MockUserProvider.new

    @listener.on_login_success self.create_event ASEC::Authenticator::Passport::SelfValidating.new(
      ASEC::Authenticator::Passport::Badge::User.new("test") { @user },
      [ASEC::Authenticator::Passport::Badge::PasswordUpgrade.new("pa$$word", upgrader)],
    )

    upgrader.calls.should eq [{"upgrade_password", "new-hash"}]
    @hasher.hash_calls.should eq ["pa$$word"]
  end

  def test_upgrade_without_upgrader : Nil
    user_provider = MockUserProvider.new load_result: @user
    user_badge = ASEC::Authenticator::Passport::Badge::User.new "test"
    user_badge.user_provider = user_provider

    @listener.on_login_success self.create_event ASEC::Authenticator::Passport::SelfValidating.new(user_badge, [ASEC::Authenticator::Passport::Badge::PasswordUpgrade.new("pa$$word")])

    user_provider.calls.should eq [{"load_user_by_identifier", "test"}, {"upgrade_password", "new-hash"}]
  end

  def test_no_upgrade_without_upgrader_if_the_user_provider_is_not_an_upgrader : Nil
    user_badge = ASEC::Authenticator::Passport::Badge::User.new "John"
    user_badge.user_provider = ASEC::User::Provider::InMemory.new [@user]

    @listener.on_login_success self.create_event ASEC::Authenticator::Passport::SelfValidating.new(user_badge, [ASEC::Authenticator::Passport::Badge::PasswordUpgrade.new("pa$$word")])

    @hasher.hash_calls.should be_empty
  end

  def test_no_upgrade_without_upgrader_for_a_custom_user_loader : Nil
    @listener.on_login_success self.create_event ASEC::Authenticator::Passport::SelfValidating.new(
      ASEC::Authenticator::Passport::Badge::User.new("test") { @user },
      [ASEC::Authenticator::Passport::Badge::PasswordUpgrade.new("pa$$word")],
    )

    @hasher.hash_calls.should be_empty
  end

  def test_no_upgrade_if_no_rehash_is_needed : Nil
    upgrader = MockUserProvider.new

    ASEC::Listeners::PasswordMigrating.new(MockPasswordHasherFactory.new).on_login_success self.create_event ASEC::Authenticator::Passport::SelfValidating.new(
      ASEC::Authenticator::Passport::Badge::User.new("test") { @user },
      [ASEC::Authenticator::Passport::Badge::PasswordUpgrade.new("pa$$word", upgrader)],
    )

    upgrader.calls.should be_empty
  end

  def test_user_without_password : Nil
    user = ASEC::User::InMemory.new "test", nil
    hasher_factory = MockPasswordHasherFactory.new

    ASEC::Listeners::PasswordMigrating.new(hasher_factory).on_login_success self.create_event ASEC::Authenticator::Passport::SelfValidating.new(
      ASEC::Authenticator::Passport::Badge::User.new("test") { user },
      [ASEC::Authenticator::Passport::Badge::PasswordUpgrade.new("pa$$word")],
    )

    hasher_factory.calls.should eq 0
  end

  def test_user_not_password_authenticated : Nil
    hasher_factory = MockPasswordHasherFactory.new

    ASEC::Listeners::PasswordMigrating.new(hasher_factory).on_login_success self.create_event ASEC::Authenticator::Passport::SelfValidating.new(
      ASEC::Authenticator::Passport::Badge::User.new("test") { TestUser.new },
      [ASEC::Authenticator::Passport::Badge::PasswordUpgrade.new("pa$$word")],
    )

    hasher_factory.calls.should eq 0
  end

  private def create_event(passport : ASEC::Authenticator::Passport) : ASEC::Events::LoginSuccess
    ASEC::Events::LoginSuccess.new MockAuthenticator.new, passport, ASEC::Authentication::Token::Null.new, new_request, nil, "main"
  end
end
