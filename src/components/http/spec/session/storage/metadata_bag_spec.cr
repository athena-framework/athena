require "../../spec_helper"

private def load(bag : AHTTP::Session::Storage::MetadataBag, json : String) : Nil
  bag.load JSON::PullParser.new json
end

struct AHTTP::Session::Storage::MetadataBagTest < ASPEC::TestCase
  def test_load_new_session : Nil
    clock = ACLK::Spec::MockClock.new
    bag = AHTTP::Session::Storage::MetadataBag.new clock: clock
    bag.load nil

    bag.created.should eq Time.unix(clock.now.to_unix)
    bag.last_used.should eq Time.unix(clock.now.to_unix)
    bag.lifetime.should eq 0
  end

  def test_load_existing_session : Nil
    clock = ACLK::Spec::MockClock.new
    bag = AHTTP::Session::Storage::MetadataBag.new clock: clock
    load bag, %({"c":1234567,"u":12345678,"l":0,"other":1})

    bag.created.should eq Time.unix(1_234_567)
    bag.last_used.should eq Time.unix(12_345_678)
  end

  def test_name : Nil
    bag = AHTTP::Session::Storage::MetadataBag.new
    bag.name.should eq "__metadata"

    bag.name = "foo"
    bag.name.should eq "foo"
  end

  def test_storage_key : Nil
    AHTTP::Session::Storage::MetadataBag.new.storage_key.should eq "_athena_meta"
    AHTTP::Session::Storage::MetadataBag.new("test").storage_key.should eq "test"
  end

  def test_lifetime : Nil
    bag = AHTTP::Session::Storage::MetadataBag.new
    load bag, %({"c":1234567,"u":12345678,"l":1000})

    bag.lifetime.should eq 1000
  end

  def test_cookie_lifetime_from_constructor : Nil
    bag = AHTTP::Session::Storage::MetadataBag.new cookie_lifetime: 1000
    bag.load nil

    bag.lifetime.should eq 1000
  end

  def test_stamp_new : Nil
    clock = ACLK::Spec::MockClock.new
    bag = AHTTP::Session::Storage::MetadataBag.new cookie_lifetime: 1000, clock: clock
    load bag, %({"c":1234567,"u":12345678,"l":0})

    bag.stamp_new
    bag.created.should eq Time.unix(clock.now.to_unix)
    bag.lifetime.should eq 1000

    bag.stamp_new 42
    bag.lifetime.should eq 42
  end

  def test_clear_does_nothing : Nil
    bag = AHTTP::Session::Storage::MetadataBag.new
    load bag, %({"c":1234567,"u":12345678,"l":0})
    bag.clear

    bag.created.should eq Time.unix(1_234_567)
    bag.empty?.should be_false
  end

  def test_skips_last_used_update_within_threshold : Nil
    clock = ACLK::Spec::MockClock.new
    timestamp = clock.now.to_unix

    bag = AHTTP::Session::Storage::MetadataBag.new update_threshold: 10, clock: clock
    load bag, %({"c":#{timestamp},"u":#{timestamp - 5},"l":0})

    JSON.build { |builder| bag.to_json builder }.should eq %({"c":#{timestamp},"u":#{timestamp - 5},"l":0})
  end

  def test_does_not_skip_last_used_update_past_threshold : Nil
    clock = ACLK::Spec::MockClock.new
    timestamp = clock.now.to_unix

    bag = AHTTP::Session::Storage::MetadataBag.new update_threshold: 10, clock: clock
    load bag, %({"c":#{timestamp},"u":#{timestamp - 15},"l":0})

    JSON.build { |builder| bag.to_json builder }.should eq %({"c":#{timestamp},"u":#{timestamp},"l":0})
    bag.last_used.should eq Time.unix(timestamp - 15)
  end

  def test_uses_the_system_time_without_a_clock : Nil
    bag = AHTTP::Session::Storage::MetadataBag.new
    bag.load nil

    bag.created.should be_close Time.utc, 2.seconds
  end
end
