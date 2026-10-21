require "../spec_helper"

# Records the calls made to the handler.
private class RecordingHandler < AHTTP::Session::Storage::Handler::Memory
  getter calls = [] of String

  def write(session_id : String, data : String) : Bool
    @calls << "write"
    super
  end

  def update_timestamp(session_id : String, data : String) : Bool
    @calls << "update_timestamp"
    super
  end

  def destroy(session_id : String) : Bool
    @calls << "destroy"
    super
  end

  def gc(max_lifetime : Int32) : Int32
    @calls << "gc"
    super
  end

  def close : Nil
    @calls << "close"
    super
  end
end

struct AHTTP::Session::StorageTest < ASPEC::TestCase
  @handler : RecordingHandler

  def initialize
    @handler = RecordingHandler.new
  end

  def test_start_creates_a_new_session : Nil
    storage = self.create_storage
    storage.id.should be_empty
    storage.started?.should be_false

    storage.start.should be_true
    storage.started?.should be_true
    storage.id.should match /\A[0-9a-f]{32}\z/
  end

  def test_start_is_idempotent : Nil
    storage = self.create_storage
    storage.start
    id = storage.id

    storage.start.should be_true
    storage.id.should eq id
  end

  def test_start_loads_an_existing_session : Nil
    id = self.persisted_session_id

    storage = self.create_storage
    storage.id = id
    storage.start

    storage.id.should eq id
    attributes(storage).get("foo", String).should eq "bar"
  end

  def test_start_replaces_an_unknown_id : Nil
    storage = self.create_storage
    storage.id = "0123456789abcdef0123456789abcdef"
    storage.start

    storage.id.should_not eq "0123456789abcdef0123456789abcdef"
    storage.id.should match /\A[0-9a-f]{32}\z/
  end

  def test_start_replaces_an_invalid_id : Nil
    storage = self.create_storage
    storage.id = "../../etc/passwd"
    storage.start

    storage.id.should match /\A[0-9a-f]{32}\z/
  end

  def test_start_treats_data_that_cannot_be_loaded_as_an_empty_session : Nil
    @handler.read "0123456789abcdef0123456789abcdef"
    @handler.write "0123456789abcdef0123456789abcdef", %({"_athena_attributes":"not an object"})

    storage = self.create_storage
    storage.id = "0123456789abcdef0123456789abcdef"
    storage.start

    attributes(storage).empty?.should be_true
  end

  def test_start_treats_out_of_range_metadata_as_an_empty_session : Nil
    @handler.read "0123456789abcdef0123456789abcdef"
    @handler.write "0123456789abcdef0123456789abcdef", %({"_athena_attributes":{"foo":"bar"},"_athena_meta":{"c":1,"u":1,"l":99999999999}})

    storage = self.create_storage
    storage.id = "0123456789abcdef0123456789abcdef"
    storage.start

    attributes(storage).empty?.should be_true
  end

  def test_start_treats_invalid_json_as_an_empty_session : Nil
    @handler.read "0123456789abcdef0123456789abcdef"
    @handler.write "0123456789abcdef0123456789abcdef", "{"

    storage = self.create_storage
    storage.id = "0123456789abcdef0123456789abcdef"
    storage.start

    attributes(storage).empty?.should be_true
  end

  def test_start_collects_garbage_based_on_probability : Nil
    self.create_storage(gc_probability: 0).start
    @handler.calls.should_not contain "gc"

    self.create_storage(gc_probability: 1, gc_divisor: 1).start
    @handler.calls.should contain "gc"
  end

  def test_set_id_after_start : Nil
    storage = self.create_storage
    storage.start

    expect_raises AHTTP::Exception::Logic, "Cannot change the ID of an active session." do
      storage.id = "0123456789abcdef0123456789abcdef"
    end
  end

  def test_name : Nil
    storage = self.create_storage
    storage.name.should eq "athena_session_id"

    storage.name = "foo"
    storage.name.should eq "foo"

    storage.start

    expect_raises AHTTP::Exception::Logic, "Cannot change the name of an active session." do
      storage.name = "bar"
    end
  end

  def test_bag : Nil
    storage = self.create_storage

    storage.bag("attributes").should be_a AHTTP::Session::AttributeBag
    storage.started?.should be_true
  end

  def test_unknown_bag : Nil
    expect_raises AHTTP::Exception::InvalidArgument, "The session bag 'foo' is not registered." do
      self.create_storage.bag "foo"
    end
  end

  def test_register_bag_for_a_started_session : Nil
    storage = self.create_storage
    storage.start

    expect_raises AHTTP::Exception::Logic, "Cannot register a bag when the session is already started." do
      storage.register_bag AHTTP::Session::FlashBag.new
    end
  end

  def test_save_persists_the_bags_and_metadata : Nil
    storage = self.create_storage
    attributes(storage).set "foo", "bar"
    storage.save

    storage.started?.should be_false
    @handler.calls.should eq ["write", "close"]

    data = JSON.parse @handler.read(storage.id)
    data["_athena_attributes"].should eq({"foo" => "bar"})
    data["_athena_meta"].as_h.keys.should eq ["c", "u", "l"]
  end

  def test_save_does_not_persist_an_empty_session : Nil
    storage = self.create_storage
    storage.start
    storage.save

    @handler.calls.should eq ["destroy", "close"]
    @handler.read(storage.id).should be_empty
  end

  def test_save_only_updates_the_timestamp_of_an_unchanged_session : Nil
    storage = self.create_storage
    storage.id = self.persisted_session_id
    storage.start
    storage.save

    @handler.calls.should eq ["update_timestamp", "close"]
  end

  def test_save_destroys_an_emptied_session : Nil
    storage = self.create_storage
    storage.id = id = self.persisted_session_id
    attributes(storage).clear
    storage.save

    @handler.calls.should eq ["destroy", "close"]
    @handler.read(id).should be_empty
  end

  def test_save_unstarted_session : Nil
    self.create_storage.save

    @handler.calls.should be_empty
  end

  def test_restart_after_save : Nil
    storage = self.create_storage
    attributes(storage).set "foo", "bar"
    storage.save
    id = storage.id

    attributes(storage).get("foo", String).should eq "bar"
    storage.started?.should be_true
    storage.id.should eq id
  end

  def test_regenerate_unstarted_session : Nil
    storage = self.create_storage
    storage.id = id = self.persisted_session_id

    storage.regenerate(destroy: true).should be_true
    storage.started?.should be_true
    storage.id.should_not eq id
    @handler.read(id).should be_empty
  end

  def test_regenerate : Nil
    storage = self.create_storage
    storage.id = id = self.persisted_session_id
    storage.start

    storage.regenerate.should be_true
    storage.id.should_not eq id
    storage.save

    JSON.parse(@handler.read(id))["_athena_attributes"].should eq({"foo" => "bar"})
    JSON.parse(@handler.read(storage.id))["_athena_attributes"].should eq({"foo" => "bar"})
  end

  def test_regenerate_destroy : Nil
    storage = self.create_storage
    storage.id = id = self.persisted_session_id
    storage.start

    storage.regenerate(destroy: true).should be_true
    storage.id.should_not eq id
    storage.save

    @handler.read(id).should be_empty
    JSON.parse(@handler.read(storage.id))["_athena_attributes"].should eq({"foo" => "bar"})
  end

  def test_regenerate_with_lifetime : Nil
    storage = self.create_storage
    storage.start

    storage.regenerate(lifetime: 1000).should be_true
    storage.metadata_bag.lifetime.should eq 1000
  end

  def test_clear : Nil
    storage = self.create_storage
    storage.id = self.persisted_session_id
    storage.clear

    storage.started?.should be_true
    attributes(storage).empty?.should be_true
  end

  private def create_storage(**options) : AHTTP::Session::Storage
    AHTTP::Session::Storage.new(@handler, **{gc_probability: 0}.merge(options)).tap do |storage|
      storage.register_bag AHTTP::Session::AttributeBag.new
    end
  end

  private def attributes(storage : AHTTP::Session::Storage) : AHTTP::Session::AttributeBag
    storage.bag("attributes").as AHTTP::Session::AttributeBag
  end

  # Returns the ID of a persisted session whose `foo` attribute is `bar`.
  private def persisted_session_id : String
    storage = self.create_storage
    attributes(storage).set "foo", "bar"
    storage.save
    @handler.calls.clear

    storage.id
  end
end
