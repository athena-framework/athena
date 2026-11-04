require "./spec_helper"

struct BundlePasswordHasherFactoryTest < ASPEC::TestCase
  def test_password_hasher_factory : Nil
    hasher = MockPasswordHasher.new

    factory = ASEC::Bundle.password_hasher_factory({"Athena::Security::User::InMemory" => hasher.as(APH::Interface)})

    factory.password_hasher(ASEC::User::InMemory.new("user", nil)).should be hasher
  end
end
