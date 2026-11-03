require "../../spec_helper"

struct InMemoryUserCheckerTest < ASPEC::TestCase
  def test_check_post_auth : Nil
    ASEC::User::Checker::InMemory.new.check_post_auth ASEC::User::InMemory.new("John", "password", [] of String, false)
  end

  def test_check_pre_auth_enabled : Nil
    ASEC::User::Checker::InMemory.new.check_pre_auth ASEC::User::InMemory.new("John", "password")
  end

  def test_check_pre_auth_other_user : Nil
    ASEC::User::Checker::InMemory.new.check_pre_auth TestUser.new
  end

  def test_check_pre_auth_disabled : Nil
    user = ASEC::User::InMemory.new "John", "password", [] of String, false

    ex = expect_raises ASEC::Exception::Disabled, "User account is disabled." do
      ASEC::User::Checker::InMemory.new.check_pre_auth user
    end

    ex.user.should be user
    ex.message_key.should eq "Account is disabled."
  end
end
