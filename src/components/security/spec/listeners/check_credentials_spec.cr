require "../spec_helper"

struct CheckCredentialsListenerTest < ASPEC::TestCase
  @user : ASEC::User::InMemory

  def initialize
    @user = ASEC::User::InMemory.new "wouter", "password-hash"
  end

  @[DataProvider("passwords")]
  def test_password_authenticated(password : String, password_valid : Bool) : Nil
    hasher = MockPasswordHasher.new password_valid
    credentials = ASEC::Authenticator::Passport::Credentials::Password.new password
    event = self.create_event ASEC::Authenticator::Passport.new(ASEC::Authenticator::Passport::Badge::User.new("wouter") { @user }, credentials)

    if password_valid
      ASEC::Listeners::CheckCredentials.new(APH::Factory.new({ASEC::User::InMemory => hasher.as APH::Interface})).check_passport event

      credentials.resolved?.should be_true
    else
      expect_raises ASEC::Exception::BadCredentials, "The presented password is invalid." do
        ASEC::Listeners::CheckCredentials.new(APH::Factory.new({ASEC::User::InMemory => hasher.as APH::Interface})).check_passport event
      end

      credentials.resolved?.should be_false
    end

    hasher.verify_calls.should eq [{"password-hash", password}]
  end

  def passwords : Tuple
    {
      {"ThePa$$word", true},
      {"Invalid", false},
    }
  end

  def test_empty_password : Nil
    hasher_factory = MockPasswordHasherFactory.new
    event = self.create_event ASEC::Authenticator::Passport.new(ASEC::Authenticator::Passport::Badge::User.new("wouter") { @user }, ASEC::Authenticator::Passport::Credentials::Password.new(""))

    expect_raises ASEC::Exception::BadCredentials, "The presented password cannot be empty." do
      ASEC::Listeners::CheckCredentials.new(hasher_factory).check_passport event
    end

    hasher_factory.calls.should eq 0
  end

  def test_user_without_password : Nil
    hasher_factory = MockPasswordHasherFactory.new
    user = ASEC::User::InMemory.new "wouter", nil
    event = self.create_event ASEC::Authenticator::Passport.new(ASEC::Authenticator::Passport::Badge::User.new("wouter") { user }, ASEC::Authenticator::Passport::Credentials::Password.new("password"))

    expect_raises ASEC::Exception::BadCredentials, "The presented password is invalid." do
      ASEC::Listeners::CheckCredentials.new(hasher_factory).check_passport event
    end

    hasher_factory.calls.should eq 0
  end

  def test_user_not_password_authenticated : Nil
    event = self.create_event ASEC::Authenticator::Passport.new(ASEC::Authenticator::Passport::Badge::User.new("wouter") { TestUser.new }, ASEC::Authenticator::Passport::Credentials::Password.new("password"))

    expect_raises ASEC::Exception::Logic, "Class 'TestUser' must include 'APH::PasswordAuthenticatedUserInterface' for using password-based authentication." do
      ASEC::Listeners::CheckCredentials.new(MockPasswordHasherFactory.new).check_passport event
    end
  end

  def test_already_resolved_password : Nil
    hasher_factory = MockPasswordHasherFactory.new
    credentials = ASEC::Authenticator::Passport::Credentials::Password.new "password"
    credentials.mark_resolved
    passport = ASEC::Authenticator::Passport.new ASEC::Authenticator::Passport::Badge::User.new("wouter") { @user }, credentials

    ASEC::Listeners::CheckCredentials.new(hasher_factory).check_passport self.create_event passport

    hasher_factory.calls.should eq 0
    passport.has_badge?(ASEC::Authenticator::Passport::Badge::PasswordUpgrade).should be_false
  end

  @[DataProvider("custom_authenticated_results")]
  def test_custom_authenticated(result : Bool) : Nil
    hasher_factory = MockPasswordHasherFactory.new
    credentials = ASEC::Authenticator::Passport::Credentials::Custom.new({"password" => "foo"}) { result }
    event = self.create_event ASEC::Authenticator::Passport.new(ASEC::Authenticator::Passport::Badge::User.new("wouter") { @user }, credentials)

    if result
      ASEC::Listeners::CheckCredentials.new(hasher_factory).check_passport event

      credentials.resolved?.should be_true
    else
      expect_raises ASEC::Exception::BadCredentials do
        ASEC::Listeners::CheckCredentials.new(hasher_factory).check_passport event
      end
    end

    hasher_factory.calls.should eq 0
  end

  def custom_authenticated_results : Tuple
    {
      {true},
      {false},
    }
  end

  def test_already_resolved_custom_credentials : Nil
    checks = 0
    credentials = ASEC::Authenticator::Passport::Credentials::Custom.new("token") { checks += 1; true }
    credentials.execute_custom_checker @user

    ASEC::Listeners::CheckCredentials.new(MockPasswordHasherFactory.new).check_passport self.create_event ASEC::Authenticator::Passport.new(ASEC::Authenticator::Passport::Badge::User.new("wouter") { @user }, credentials)

    checks.should eq 1
  end

  def test_no_credentials_badge_provided : Nil
    hasher_factory = MockPasswordHasherFactory.new

    ASEC::Listeners::CheckCredentials.new(hasher_factory).check_passport self.create_event ASEC::Authenticator::Passport::SelfValidating.new(ASEC::Authenticator::Passport::Badge::User.new("wouter") { @user })

    hasher_factory.calls.should eq 0
  end

  def test_adds_password_upgrade_badge : Nil
    passport = ASEC::Authenticator::Passport.new(ASEC::Authenticator::Passport::Badge::User.new("wouter") { @user }, ASEC::Authenticator::Passport::Credentials::Password.new("ThePa$$word"))

    ASEC::Listeners::CheckCredentials.new(MockPasswordHasherFactory.new).check_passport self.create_event passport

    passport.badge(ASEC::Authenticator::Passport::Badge::PasswordUpgrade).try(&.erase_plaintext_password).should eq "ThePa$$word"
  end

  def test_adds_no_password_upgrade_badge_if_it_already_exists : Nil
    upgrade_badge = ASEC::Authenticator::Passport::Badge::PasswordUpgrade.new "ThePa$$word"
    passport = ASEC::Authenticator::Passport.new(
      ASEC::Authenticator::Passport::Badge::User.new("wouter") { @user },
      ASEC::Authenticator::Passport::Credentials::Password.new("ThePa$$word"),
      [upgrade_badge],
    )

    ASEC::Listeners::CheckCredentials.new(MockPasswordHasherFactory.new).check_passport self.create_event passport

    passport.badge(ASEC::Authenticator::Passport::Badge::PasswordUpgrade).should be upgrade_badge
  end

  def test_adds_no_password_upgrade_badge_if_password_is_invalid : Nil
    passport = ASEC::Authenticator::Passport.new(ASEC::Authenticator::Passport::Badge::User.new("wouter") { @user }, ASEC::Authenticator::Passport::Credentials::Password.new("ThePa$$word"))

    expect_raises ASEC::Exception::BadCredentials do
      ASEC::Listeners::CheckCredentials.new(MockPasswordHasherFactory.new MockPasswordHasher.new(false)).check_passport self.create_event passport
    end

    passport.has_badge?(ASEC::Authenticator::Passport::Badge::PasswordUpgrade).should be_false
  end

  private def create_event(passport : ASEC::Authenticator::Passport) : ASEC::Events::CheckPassport
    ASEC::Events::CheckPassport.new MockAuthenticator.new, passport
  end
end
