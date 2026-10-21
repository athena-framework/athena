require "./spec_helper"

struct NativeTest < ASPEC::TestCase
  def test_cost_below_range : Nil
    expect_raises APH::Exception::InvalidArgument, "The cost must be in the range of 4..31." do
      APH::Native.new 3
    end
  end

  def test_cost_above_range : Nil
    expect_raises APH::Exception::InvalidArgument, "The cost must be in the range of 4..31." do
      APH::Native.new 32
    end
  end

  @[DataProvider("valid_costs")]
  def test_cost_in_range(cost : Int32) : Nil
    APH::Native.new(cost).cost.should eq cost
  end

  def valid_costs : Hash
    (4..31).to_h { |cost| {cost.to_s, {cost}} }
  end

  def test_default_cost : Nil
    APH::Native.new.cost.should eq 13
  end

  def test_validation : Nil
    hasher = APH::Native.new 4
    hash = hasher.hash "password"

    hasher.verify(hash, "password").should be_true
    hasher.verify(hash, "anotherPassword").should be_false
    hasher.verify(hash, "").should be_false
  end

  def test_hash_format : Nil
    APH::Native.new(4).hash("password").should match /\A\$2a\$04\$[.\/A-Za-z0-9]{53}\z/
  end

  def test_hash_uses_random_salt : Nil
    hasher = APH::Native.new 4

    hasher.hash("password").should_not eq hasher.hash("password")
  end

  def test_bcrypt_with_long_password : Nil
    hasher = APH::Native.new 4
    plain_password = "a" * 100

    hasher.verify("$2a$04$vkAO0GthronI4a.tCWEqq.2v3ehLws/LXy0ljI2EPj8toa4OEpg.6", plain_password).should be_false
    hasher.verify(hasher.hash(plain_password), plain_password).should be_true
    hasher.verify(hasher.hash(plain_password), "a" * 72).should be_false
  end

  def test_password_nul_byte_gracefully_handled : Nil
    hasher = APH::Native.new 4
    plain_password = "a\0b"

    hasher.verify(hasher.hash(plain_password), plain_password).should be_true
    hasher.verify(hasher.hash(plain_password), "a").should be_false
  end

  def test_verify_non_bcrypt_hash : Nil
    hasher = APH::Native.new 4

    hasher.verify("$6$abcdefgh$yVfUwsw5T.JApa8POvClA1pQ5peiq97DUNyXCZN5IrF.BMSkiaLQ5kvpuEm/VQ1Tvh/KV2TcaWh8qinoW5dhA1", "password").should be_false
    hasher.verify("$2a$xx$bZmziC9015nFazIvUpIUa.AUNkZuKemn3EVWG2EVweiWa33MedTXS", "password").should be_false
    hasher.verify("dummyhash", "password").should be_false
  end

  @[DataProvider("malformed_hashes")]
  def test_verify_malformed_hash(hashed_password : String) : Nil
    APH::Native.new(4).verify(hashed_password, "password").should be_false
  end

  @[DataProvider("malformed_hashes")]
  def test_needs_rehash_malformed_hash(hashed_password : String) : Nil
    APH::Native.new(4).needs_rehash?(hashed_password).should be_true
  end

  # Variants of `$2a$04$uIXG1haYWCcUKgnFS0N83umHwvG38OfEfWDbHvbro0jXjJNf2.OKy`, the hash of `password`.
  def malformed_hashes : Hash
    {
      "missing salt and digest"  => {"$2a$04$"},
      "truncated salt"           => {"$2a$04$uIXG1haYWCcU"},
      "invalid salt character"   => {"$2a$04$!IXG1haYWCcUKgnFS0N83umHwvG38OfEfWDbHvbro0jXjJNf2.OKy"},
      "multibyte salt character" => {"$2a$04$éIXG1haYWCcUKgnFS0N83umHwvG38OfEfWDbHvbro0jXjJNf2.OKy"},
      "single digit cost"        => {"$2a$4$uIXG1haYWCcUKgnFS0N83umHwvG38OfEfWDbHvbro0jXjJNf2.OKy"},
    }
  end

  def test_needs_rehash : Nil
    hasher = APH::Native.new 4

    hasher.needs_rehash?("dummyhash").should be_true
    hasher.needs_rehash?("$2a$xx$bZmziC9015nFazIvUpIUa.AUNkZuKemn3EVWG2EVweiWa33MedTXS").should be_true

    hash = hasher.hash "foo"
    hasher.needs_rehash?(hash).should be_false

    APH::Native.new(5).needs_rehash?(hash).should be_true
  end

  def test_hash_too_long_password_raises : Nil
    expect_raises APH::Exception::InvalidPassword, "Invalid password." do
      APH::Native.new(4).hash "a" * 5000
    end
  end

  def test_verify_too_long_password : Nil
    hasher = APH::Native.new 4

    hasher.verify(hasher.hash("a" * 4096), "a" * 4097).should be_false
  end
end
