require "../spec_helper"

private class CustomUserBadge < ASEC::Authenticator::Passport::Badge::User; end

struct PassportTest < ASPEC::TestCase
  def test_user : Nil
    user = TestUser.new
    loads = 0

    passport = ASEC::Authenticator::Passport.new(
      ASEC::Authenticator::Passport::Badge::User.new("user") { loads += 1; user },
      ASEC::Authenticator::Passport::Credentials::Password.new("password"),
    )

    passport.user.should be user
    passport.user.should be user
    loads.should eq 1
  end

  def test_user_without_user_badge : Nil
    passport = ASEC::Authenticator::Passport::SelfValidating.new ASEC::Authenticator::Passport::Badge::User.new("user") { TestUser.new }
    passport.add_badge ASEC::Authenticator::Passport::Badge::PasswordUpgrade.new("password"), ASEC::Authenticator::Passport::Badge::User

    expect_raises ASEC::Exception::Logic, "Cannot get the Security user, no username or 'ASEC::Authenticator::Passport::Badge::User' configured for this passport." do
      passport.user
    end
  end

  def test_badges : Nil
    user_badge = ASEC::Authenticator::Passport::Badge::User.new "user"
    credentials = ASEC::Authenticator::Passport::Credentials::Password.new "password"
    upgrade_badge = ASEC::Authenticator::Passport::Badge::PasswordUpgrade.new "password"

    passport = ASEC::Authenticator::Passport.new user_badge, credentials, [upgrade_badge]

    passport.badges.should eq [user_badge, credentials, upgrade_badge]
    passport.has_badge?(ASEC::Authenticator::Passport::Credentials::Password).should be_true
    passport.has_badge?(ASEC::Authenticator::Passport::Credentials::Custom).should be_false
    passport.badge(ASEC::Authenticator::Passport::Credentials::Password).should be credentials
    passport.badge(ASEC::Authenticator::Passport::Credentials::Custom).should be_nil
  end

  def test_add_badge_replaces_the_badge_of_the_same_type : Nil
    passport = ASEC::Authenticator::Passport::SelfValidating.new ASEC::Authenticator::Passport::Badge::User.new("user")
    upgrade_badge = ASEC::Authenticator::Passport::Badge::PasswordUpgrade.new "new"

    passport.add_badge(ASEC::Authenticator::Passport::Badge::PasswordUpgrade.new "old").add_badge(upgrade_badge)

    passport.badges.size.should eq 2
    passport.badge(ASEC::Authenticator::Passport::Badge::PasswordUpgrade).should be upgrade_badge
  end

  def test_add_badge_as_another_badge_class : Nil
    user = TestUser.new
    passport = ASEC::Authenticator::Passport::SelfValidating.new ASEC::Authenticator::Passport::Badge::User.new("user")
    custom_badge = CustomUserBadge.new("custom") { user }

    passport.add_badge custom_badge, ASEC::Authenticator::Passport::Badge::User

    passport.has_badge?(CustomUserBadge).should be_false
    passport.badge(ASEC::Authenticator::Passport::Badge::User).should be custom_badge
    passport.user.should be user
  end
end
