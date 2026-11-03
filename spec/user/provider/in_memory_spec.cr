require "../../spec_helper"

struct InMemoryUserProviderTest < ASPEC::TestCase
  def test_initialize : Nil
    user = self.create_provider.load_user_by_identifier("fabien").as ASEC::User::InMemory

    user.password.should eq "foo"
    user.roles.should eq ["ROLE_USER"]
    user.enabled?.should be_false
  end

  def test_load_user_by_identifier_returns_a_copy : Nil
    provider = self.create_provider

    user = provider.load_user_by_identifier("fabien").as ASEC::User::InMemory
    user.roles << "ROLE_ADMIN"

    provider.load_user_by_identifier("fabien").roles.should eq ["ROLE_USER"]
  end

  def test_load_user_by_identifier_is_case_insensitive : Nil
    self.create_provider.load_user_by_identifier("FaBiEn").user_identifier.should eq "fabien"
  end

  def test_refresh_user : Nil
    refreshed_user = self.create_provider.refresh_user(ASEC::User::InMemory.new "fabien", "bar").as ASEC::User::InMemory

    refreshed_user.password.should eq "foo"
    refreshed_user.roles.should eq ["ROLE_USER"]
    refreshed_user.enabled?.should be_false
  end

  def test_refresh_user_unsupported : Nil
    expect_raises ASEC::Exception::UnsupportedUser, "Instances of 'TestUser' are not supported." do
      self.create_provider.refresh_user TestUser.new "fabien"
    end
  end

  def test_create_user : Nil
    provider = ASEC::User::Provider::InMemory.new
    provider.create_user ASEC::User::InMemory.new "fabien", "foo"

    provider.load_user_by_identifier("fabien").as(ASEC::User::InMemory).password.should eq "foo"
  end

  def test_create_user_already_exists : Nil
    provider = ASEC::User::Provider::InMemory.new
    provider.create_user ASEC::User::InMemory.new "fabien", "foo"

    expect_raises ASEC::Exception::Logic, "Another user with the same username already exists." do
      provider.create_user ASEC::User::InMemory.new "FABIEN", "foo"
    end
  end

  def test_load_user_by_identifier_does_not_exist : Nil
    ex = expect_raises ASEC::Exception::UserNotFound, "Username 'fabien' does not exist." do
      ASEC::User::Provider::InMemory.new.load_user_by_identifier "fabien"
    end

    ex.user_identifier.should eq "fabien"
  end

  def test_supports_class : Nil
    provider = ASEC::User::Provider::InMemory.new

    provider.supports_class?(ASEC::User::InMemory).should be_true
    provider.supports_class?(TestUser).should be_false
  end

  private def create_provider : ASEC::User::Provider::InMemory
    ASEC::User::Provider::InMemory.new [
      ASEC::User::InMemory.new("fabien", "foo", ["ROLE_USER"], false),
    ]
  end
end
