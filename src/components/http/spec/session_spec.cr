require "./spec_helper"

struct AHTTP::SessionTest < ASPEC::TestCase
  @handler : AHTTP::Session::Storage::Handler::Memory

  def initialize
    @handler = AHTTP::Session::Storage::Handler::Memory.new
  end

  def test_start : Nil
    session = self.create_session
    session.started?.should be_false
    session.id.should be_empty

    session.start.should be_true
    session.started?.should be_true
    session.id.should_not be_empty
  end

  def test_set_id : Nil
    session = self.create_session
    session.id = "0123456789abcdef0123456789abcdef"
    session.id.should eq "0123456789abcdef0123456789abcdef"
  end

  def test_set_same_id_after_start : Nil
    session = self.create_session
    session.start

    session.id = session.id
  end

  def test_name : Nil
    session = self.create_session
    session.name.should eq "athena_session_id"

    session.name = "foo"
    session.name.should eq "foo"
  end

  def test_attributes : Nil
    session = self.create_session

    session.has?("foo").should be_false
    session.get?("foo", String).should be_nil

    session.set "foo", "bar"
    session.has?("foo").should be_true
    session.get("foo", String).should eq "bar"
    session.get?("foo", String).should eq "bar"
    session.all.should eq({"foo" => %("bar")})

    session.remove "foo"
    session.has?("foo").should be_false

    session.set "foo", "bar"
    session.clear
    session.all.should be_empty
  end

  def test_invalidate : Nil
    session = self.create_session
    session.set "foo", "bar"
    session.save
    id = session.id

    session.invalidate.should be_true
    session.all.should be_empty
    session.id.should_not eq id
    @handler.read(id).should be_empty
  end

  def test_migrate : Nil
    session = self.create_session
    session.set "foo", "bar"
    session.save
    id = session.id

    session.migrate.should be_true
    session.get("foo", String).should eq "bar"
    session.id.should_not eq id
    @handler.read(id).should_not be_empty
  end

  def test_migrate_destroy : Nil
    session = self.create_session
    session.set "foo", "bar"
    session.save
    id = session.id

    session.migrate(destroy: true).should be_true
    session.get("foo", String).should eq "bar"
    session.id.should_not eq id
    @handler.read(id).should be_empty
  end

  def test_save : Nil
    session = self.create_session
    session.set "foo", "bar"
    session.save

    session.started?.should be_false

    other_session = self.create_session
    other_session.id = session.id
    other_session.get("foo", String).should eq "bar"
  end

  def test_flash_bag : Nil
    session = self.create_session
    session.flash_bag.add "notice", "foo"
    session.save

    other_session = self.create_session
    other_session.id = session.id
    other_session.flash_bag.get("notice").should eq ["foo"]
  end

  def test_metadata_bag : Nil
    self.create_session.metadata_bag.should be_a AHTTP::Session::Storage::MetadataBag
  end

  def test_register_bag : Nil
    session = self.create_session
    bag = AHTTP::Session::AttributeBag.new "_custom"
    bag.name = "custom"
    session.register_bag bag

    session.bag("custom").should be bag
  end

  def test_empty : Nil
    session = self.create_session
    session.empty?.should be_true
    session.started?.should be_false

    session.flash_bag.add "notice", "foo"
    session.empty?.should be_false

    session.flash_bag.clear
    session.empty?.should be_true
  end

  def test_usage_index : Nil
    reports = 0
    session = self.create_session usage_reporter: -> { reports += 1; nil }

    session.empty?
    session.usage_index.should eq 0

    session.has? "foo"
    session.usage_index.should eq 1

    session.empty?
    session.metadata_bag
    session.usage_index.should eq 3
    reports.should eq 3
  end

  def test_usage_index_can_suppress_reporting : Nil
    reports = 0
    session = self.create_session usage_reporter: -> { reports += 1; nil }

    session.usage_index = Int32::MIN
    session.has? "foo"

    reports.should eq 0
  end

  private def create_session(usage_reporter : Proc(Nil)? = nil) : AHTTP::Session
    AHTTP::Session.new AHTTP::Session::Storage.new(@handler), usage_reporter: usage_reporter
  end
end
