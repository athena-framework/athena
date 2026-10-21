require "../../spec_helper"

struct AHTTP::Session::Storage::FactoryTest < ASPEC::TestCase
  def test_create_storage : Nil
    handler = AHTTP::Session::Storage::Handler::Memory.new
    clock = ACLK::Spec::MockClock.new
    factory = AHTTP::Session::Storage::Factory.new handler, name: "foo", cookie_lifetime: 1000, clock: clock

    storage = factory.create_storage(nil).as AHTTP::Session::Storage
    storage.name.should eq "foo"

    storage.start
    storage.metadata_bag.lifetime.should eq 1000
    storage.metadata_bag.created.should eq Time.unix(clock.now.to_unix)
  end

  def test_create_storage_creates_a_new_storage_each_time : Nil
    factory = AHTTP::Session::Storage::Factory.new AHTTP::Session::Storage::Handler::Memory.new

    factory.create_storage(nil).should_not be factory.create_storage(nil)
    factory.create_storage(nil).metadata_bag.should_not be factory.create_storage(nil).metadata_bag
  end
end
