require "./spec_helper"

struct MigratingTest < ASPEC::TestCase
  def test_validation : Nil
    extra_hasher = MockPasswordHasher.new
    hasher = APH::Migrating.new APH::Native.new(4), extra_hasher

    hasher.needs_rehash?("foo").should be_true

    hash = hasher.hash "foo"
    hasher.needs_rehash?(hash).should be_false

    hasher.verify(hash, "foo").should be_true
    hasher.verify(hash, "bar").should be_false

    extra_hasher.calls.should be_empty
  end

  def test_fallback : Nil
    valid_hasher = MockPasswordHasher.new valid: true

    APH::Migrating.new(APH::Native.new(4), valid_hasher).verify("abc", "foo").should be_true
    valid_hasher.calls.should eq [{"verify", ["abc", "foo"]}]

    invalid_hasher = MockPasswordHasher.new valid: false

    APH::Migrating.new(APH::Native.new(4), invalid_hasher).verify("abc", "foo").should be_false
    APH::Migrating.new(APH::Native.new(4), invalid_hasher, valid_hasher).verify("abc", "foo").should be_true
  end
end
