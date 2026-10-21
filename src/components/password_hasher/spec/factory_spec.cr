require "./spec_helper"

struct FactoryTest < ASPEC::TestCase
  def test_hasher_configured_for_interface : Nil
    hasher = APH::Native.new 4
    factory = APH::Factory.new({APH::PasswordAuthenticatedUserInterface => hasher})

    factory.password_hasher(TestPasswordAuthenticatedUser.new).should be hasher
  end

  def test_hasher_configured_for_concrete_type : Nil
    hasher = APH::Native.new 4
    factory = APH::Factory.new({SomeUser => hasher})

    factory.password_hasher(SomeUser.new).should be hasher
  end

  def test_hasher_configured_for_parent_type : Nil
    hasher = APH::Native.new 4
    factory = APH::Factory.new({SomeUser => hasher})

    factory.password_hasher(SomeChildUser.new).should be hasher
  end

  def test_first_matching_hasher_wins : Nil
    child_hasher = APH::Native.new 4
    default_hasher = APH::Native.new 5
    factory = APH::Factory.new({
      SomeChildUser                           => child_hasher,
      APH::PasswordAuthenticatedUserInterface => default_hasher,
    })

    factory.password_hasher(SomeChildUser.new).should be child_hasher
    factory.password_hasher(SomeUser.new).should be default_hasher
  end

  def test_hasher_configured_for_type_name : Nil
    hasher = APH::Native.new 4
    factory = APH::Factory.new({"SomeUser" => hasher})

    factory.password_hasher(SomeChildUser.new).should be hasher
  end

  def test_hasher_configured_for_aliased_type : Nil
    hasher = APH::Native.new 4
    factory = APH::Factory.new({APH::PasswordAuthenticatedUserInterface => hasher})

    factory.password_hasher(TestPasswordAuthenticatedUser.new).should be hasher
    factory.password_hasher("Athena::PasswordHasher::PasswordAuthenticatedUserInterface").should be hasher
  end

  def test_hasher_configured_for_indirectly_included_interface : Nil
    hasher = APH::Native.new 4
    factory = APH::Factory.new({APH::PasswordAuthenticatedUserInterface => hasher})

    factory.password_hasher(IndirectUser.new).should be hasher
  end

  def test_hasher_configured_for_hasher_aware_only_type : Nil
    hasher = APH::Native.new 4
    factory = APH::Factory.new({APH::PasswordHasherAwareInterface => hasher})

    factory.password_hasher(HasherAwareOnlyUser.new).should be hasher
  end

  def test_hasher_for_user_typed_as_hasher_aware_interface : Nil
    named_hasher = APH::Native.new 4
    default_hasher = APH::Native.new 5
    factory = APH::Factory.new({
      APH::PasswordHasherAwareInterface => default_hasher,
      "hasher_name"                     => named_hasher,
    })

    users = [HasherAwareUser.new, HasherAwareOnlyUser.new] of APH::PasswordHasherAwareInterface

    users.map { |user| factory.password_hasher user }.should eq [named_hasher, default_hasher]
  end

  def test_hasher_for_user_typed_as_interface : Nil
    child_hasher = APH::Native.new 4
    default_hasher = APH::Native.new 5
    factory = APH::Factory.new({
      SomeChildUser                           => child_hasher,
      APH::PasswordAuthenticatedUserInterface => default_hasher,
    })

    # Includes both user interfaces.
    hasher_aware_user = HasherAwareUser.new
    hasher_aware_user.password_hasher_name = nil

    users = [SomeChildUser.new, SomeUser.new, hasher_aware_user] of APH::PasswordAuthenticatedUserInterface

    users.map { |user| factory.password_hasher user }.should eq [child_hasher, default_hasher, default_hasher]
  end

  def test_named_hasher_for_hasher_aware : Nil
    named_hasher = APH::Native.new 4
    factory = APH::Factory.new({
      HasherAwareUser => APH::Native.new(5),
      "hasher_name"   => named_hasher,
    })

    factory.password_hasher(HasherAwareUser.new).should be named_hasher
  end

  def test_nil_named_hasher_for_hasher_aware : Nil
    type_hasher = APH::Native.new 4
    factory = APH::Factory.new({
      HasherAwareUser => type_hasher,
      "hasher_name"   => APH::Native.new(5),
    })

    user = HasherAwareUser.new
    user.password_hasher_name = nil

    factory.password_hasher(user).should be type_hasher
  end

  def test_invalid_named_hasher_for_hasher_aware : Nil
    factory = APH::Factory.new({
      HasherAwareUser => APH::Native.new(4),
      "hasher_name"   => APH::Native.new(5),
    })

    user = HasherAwareUser.new
    user.password_hasher_name = "invalid_hasher_name"

    expect_raises APH::Exception::Runtime, %(The password hasher "invalid_hasher_name" was not configured.) do
      factory.password_hasher user
    end
  end

  def test_no_hasher_configured : Nil
    factory = APH::Factory.new({SomeUser => APH::Native.new(4)})

    expect_raises APH::Exception::Runtime, %(No password hasher has been configured for account "TestPasswordAuthenticatedUser".) do
      factory.password_hasher TestPasswordAuthenticatedUser.new
    end
  end

  def test_hasher_by_name : Nil
    hasher = APH::Native.new 4
    factory = APH::Factory.new({SomeUser => APH::Native.new(5), "auto" => hasher})

    factory.password_hasher("auto").should be hasher
  end

  def test_hasher_by_type_name : Nil
    hasher = APH::Native.new 4
    factory = APH::Factory.new({SomeUser => hasher})

    factory.password_hasher("SomeUser").should be hasher
  end

  def test_hasher_by_unknown_name : Nil
    factory = APH::Factory.new({SomeUser => APH::Native.new(4)})

    expect_raises APH::Exception::Runtime, %(No password hasher has been configured for account "Foo::Bar::User".) do
      factory.password_hasher "Foo::Bar::User"
    end
  end
end
