require "../../spec_helper"

struct ChainUserProviderTest < ASPEC::TestCase
  def test_load_user_by_identifier : Nil
    account = ASEC::User::InMemory.new "John", "password"
    provider1 = MockUserProvider.new load_result: ASEC::Exception::UserNotFound.new("not found")
    provider2 = MockUserProvider.new load_result: account

    ASEC::User::Provider::Chain.new([provider1, provider2] of ASEC::User::Provider::Interface).load_user_by_identifier("foo").should be account

    provider1.calls.should eq [{"load_user_by_identifier", "foo"}]
    provider2.calls.should eq [{"load_user_by_identifier", "foo"}]
  end

  def test_load_user_by_identifier_not_found : Nil
    provider1 = MockUserProvider.new load_result: ASEC::Exception::UserNotFound.new("not found")
    provider2 = MockUserProvider.new load_result: ASEC::Exception::UserNotFound.new("not found")

    ex = expect_raises ASEC::Exception::UserNotFound, "There is no user with identifier 'foo'." do
      ASEC::User::Provider::Chain.new([provider1, provider2] of ASEC::User::Provider::Interface).load_user_by_identifier "foo"
    end

    ex.user_identifier.should eq "foo"
    provider1.calls.should eq [{"load_user_by_identifier", "foo"}]
    provider2.calls.should eq [{"load_user_by_identifier", "foo"}]
  end

  def test_refresh_user : Nil
    account = ASEC::User::InMemory.new "John", "password"
    provider1 = MockUserProvider.new supports: false
    provider2 = MockUserProvider.new refresh_result: ASEC::Exception::UnsupportedUser.new("unsupported")
    provider3 = MockUserProvider.new refresh_result: account

    ASEC::User::Provider::Chain.new([provider1, provider2, provider3] of ASEC::User::Provider::Interface).refresh_user(ASEC::User::InMemory.new "John", "password").should be account

    provider1.calls.should eq [{"supports_class?", "Athena::Security::User::InMemory"}]
    provider2.calls.should eq [{"supports_class?", "Athena::Security::User::InMemory"}, {"refresh_user", "John"}]
    provider3.calls.should eq [{"supports_class?", "Athena::Security::User::InMemory"}, {"refresh_user", "John"}]
  end

  def test_refresh_user_again : Nil
    account = ASEC::User::InMemory.new "John", "password"
    provider1 = MockUserProvider.new refresh_result: ASEC::Exception::UserNotFound.new("not found")
    provider2 = MockUserProvider.new refresh_result: account

    ASEC::User::Provider::Chain.new([provider1, provider2] of ASEC::User::Provider::Interface).refresh_user(ASEC::User::InMemory.new "John", "password").should be account
  end

  def test_refresh_user_not_found : Nil
    provider1 = MockUserProvider.new refresh_result: ASEC::Exception::UserNotFound.new("not found")
    provider2 = MockUserProvider.new refresh_result: ASEC::Exception::UnsupportedUser.new("unsupported")

    ex = expect_raises ASEC::Exception::UserNotFound, "There is no user with name 'John'." do
      ASEC::User::Provider::Chain.new([provider1, provider2] of ASEC::User::Provider::Interface).refresh_user ASEC::User::InMemory.new "John", "password"
    end

    ex.user_identifier.should eq "John"
  end

  def test_refresh_user_unsupported : Nil
    provider1 = MockUserProvider.new refresh_result: ASEC::Exception::UnsupportedUser.new("unsupported")
    provider2 = MockUserProvider.new refresh_result: ASEC::Exception::UnsupportedUser.new("unsupported")

    expect_raises ASEC::Exception::UnsupportedUser, "There is no user provider for user 'Athena::Security::User::InMemory'." do
      ASEC::User::Provider::Chain.new([provider1, provider2] of ASEC::User::Provider::Interface).refresh_user ASEC::User::InMemory.new "John", "password"
    end
  end

  def test_supports_class : Nil
    provider1 = MockUserProvider.new supports: false
    provider2 = MockUserProvider.new supports: true

    ASEC::User::Provider::Chain.new([provider1, provider2] of ASEC::User::Provider::Interface).supports_class?(TestUser).should be_true

    provider1.calls.should eq [{"supports_class?", "TestUser"}]
    provider2.calls.should eq [{"supports_class?", "TestUser"}]
  end

  def test_supports_class_not_supported : Nil
    provider1 = MockUserProvider.new supports: false
    provider2 = MockUserProvider.new supports: false

    ASEC::User::Provider::Chain.new([provider1, provider2] of ASEC::User::Provider::Interface).supports_class?(TestUser).should be_false
  end

  def test_providers : Nil
    providers = [MockUserProvider.new, MockUserProvider.new] of ASEC::User::Provider::Interface

    ASEC::User::Provider::Chain.new(providers).providers.should eq providers
  end

  def test_upgrade_password : Nil
    user = TestPasswordAuthenticatedUser.new
    provider1 = MockUserProvider.new upgrade_exception: ASEC::Exception::UnsupportedUser.new("unsupported")
    provider2 = MockUserProviderWithoutUpgrade.new
    provider3 = MockUserProvider.new

    ASEC::User::Provider::Chain.new([provider1, provider2, provider3] of ASEC::User::Provider::Interface).upgrade_password user, "foobar"

    provider1.calls.should eq [{"upgrade_password", "foobar"}]
    provider3.calls.should eq [{"upgrade_password", "foobar"}]
  end
end
