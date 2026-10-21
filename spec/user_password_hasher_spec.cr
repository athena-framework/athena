require "./spec_helper"

struct UserPasswordHasherTest < ASPEC::TestCase
  def test_hash_password : Nil
    user = TestPasswordAuthenticatedUser.new
    hasher = MockPasswordHasher.new hash: "hash"

    APH::UserPasswordHasher.new(APH::Factory.new({TestPasswordAuthenticatedUser => hasher})).hash_password(user, "plainPassword").should eq "hash"
    hasher.calls.should eq [{"hash", ["plainPassword"]}]
  end

  def test_password_valid : Nil
    user = TestPasswordAuthenticatedUser.new "hash"
    hasher = MockPasswordHasher.new valid: true

    APH::UserPasswordHasher.new(APH::Factory.new({TestPasswordAuthenticatedUser => hasher})).password_valid?(user, "plainPassword").should be_true
    hasher.calls.should eq [{"verify", ["hash", "plainPassword"]}]
  end

  def test_password_valid_without_password : Nil
    hasher = MockPasswordHasher.new valid: true

    APH::UserPasswordHasher.new(APH::Factory.new({TestPasswordAuthenticatedUser => hasher})).password_valid?(TestPasswordAuthenticatedUser.new, "plainPassword").should be_false
    hasher.calls.should be_empty
  end

  def test_needs_rehash : Nil
    user = TestPasswordAuthenticatedUser.new

    user.password = APH::UserPasswordHasher.new(APH::Factory.new({TestPasswordAuthenticatedUser => APH::Native.new(4)})).hash_password user, "foo"

    APH::UserPasswordHasher.new(APH::Factory.new({TestPasswordAuthenticatedUser => APH::Native.new(4)})).needs_rehash?(user).should be_false
    APH::UserPasswordHasher.new(APH::Factory.new({TestPasswordAuthenticatedUser => APH::Native.new(5)})).needs_rehash?(user).should be_true
  end

  def test_needs_rehash_without_password : Nil
    hasher = MockPasswordHasher.new needs_rehash: true

    APH::UserPasswordHasher.new(APH::Factory.new({TestPasswordAuthenticatedUser => hasher})).needs_rehash?(TestPasswordAuthenticatedUser.new).should be_false
    hasher.calls.should be_empty
  end
end
