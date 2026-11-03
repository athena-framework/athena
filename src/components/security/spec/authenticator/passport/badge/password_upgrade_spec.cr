require "../../../spec_helper"

struct PasswordUpgradeBadgeTest < ASPEC::TestCase
  def test_erase_plaintext_password : Nil
    badge = ASEC::Authenticator::Passport::Badge::PasswordUpgrade.new "password"

    badge.resolved?.should be_true
    badge.password_upgrader.should be_nil
    badge.erase_plaintext_password.should eq "password"

    expect_raises ASEC::Exception::Logic, "The password is erased as another listener already used this badge." do
      badge.erase_plaintext_password
    end
  end

  def test_password_upgrader : Nil
    upgrader = MockUserProvider.new

    ASEC::Authenticator::Passport::Badge::PasswordUpgrade.new("password", upgrader).password_upgrader.should be upgrader
  end
end
