require "../spec_helper"

struct InMemoryUserTest < ASPEC::TestCase
  def test_empty_username : Nil
    expect_raises ASEC::Exception::InvalidArgument, "The username cannot be empty." do
      ASEC::User::InMemory.new "", "superpass"
    end
  end

  def test_roles : Nil
    ASEC::User::InMemory.new("fabien", "superpass").roles.should be_empty
    ASEC::User::InMemory.new("fabien", "superpass", ["ROLE_ADMIN"]).roles.should eq ["ROLE_ADMIN"]
  end

  def test_password : Nil
    ASEC::User::InMemory.new("fabien", "superpass").password.should eq "superpass"
  end

  def test_user_identifier : Nil
    ASEC::User::InMemory.new("fabien", "superpass").user_identifier.should eq "fabien"
  end

  def test_enabled : Nil
    ASEC::User::InMemory.new("mathilde", "k").enabled?.should be_true
    ASEC::User::InMemory.new("robin", "superpass", [] of String, false).enabled?.should be_false
  end

  def test_to_s : Nil
    ASEC::User::InMemory.new("fabien", "superpass").to_s.should eq "fabien"
  end

  @[DataProvider("equal_to_data")]
  def test_equal_to(expected : Bool, a : ASEC::User::InMemory, b : ASEC::User::InMemory) : Nil
    a.equal_to?(b).should eq expected
    b.equal_to?(a).should eq expected
  end

  def equal_to_data : Tuple
    {
      {true, ASEC::User::InMemory.new("username", "password"), ASEC::User::InMemory.new("username", "password")},
      {false, ASEC::User::InMemory.new("username", "password", ["ROLE"]), ASEC::User::InMemory.new("username", "password")},
      {false, ASEC::User::InMemory.new("username", "password", ["ROLE"]), ASEC::User::InMemory.new("username", "password", ["NO ROLE"])},
      {false, ASEC::User::InMemory.new("username", "password", ["ROLE", "ROLE"]), ASEC::User::InMemory.new("username", "password", ["ROLE", "NO ROLE"])},
      {false, ASEC::User::InMemory.new("username", "diff"), ASEC::User::InMemory.new("username", "password")},
      {false, ASEC::User::InMemory.new("diff", "password"), ASEC::User::InMemory.new("username", "password")},
      {false, ASEC::User::InMemory.new("username", "password", [] of String, false), ASEC::User::InMemory.new("username", "password")},
    }
  end

  def test_equal_to_different_user_type : Nil
    ASEC::User::InMemory.new("username", "password").equal_to?(TestUser.new "username").should be_false
  end
end
