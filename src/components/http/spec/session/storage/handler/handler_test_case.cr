require "../../../spec_helper"

# Exposes the protected write methods, to test them without having to race two handlers.
class AHTTP::Session::Storage::Handler::AbstractHandler
  def create(session_id : String, data : String) : Bool
    self.do_create session_id, data
  end

  def update(session_id : String, data : String) : Bool
    self.do_write session_id, data
  end
end

# Behavior every `AHTTP::Session::Storage::Handler::AbstractHandler` has to provide.
abstract struct HandlerTestCase < ASPEC::TestCase
  SESSION_ID       = "0123456789abcdef0123456789abcdef"
  OTHER_SESSION_ID = "fedcba9876543210fedcba9876543210"

  abstract def create_handler(max_lifetime : Int32 = 1440) : AHTTP::Session::Storage::Handler::AbstractHandler

  def test_read_unknown_session : Nil
    self.create_handler.read(SESSION_ID).should eq ""
  end

  def test_write_creates_a_new_session : Nil
    handler = self.create_handler

    handler.read(SESSION_ID).should eq ""
    handler.write(SESSION_ID, "data").should be_true
    handler.read(SESSION_ID).should eq "data"
  end

  def test_write_updates_an_existing_session : Nil
    handler = self.existing_session

    handler.read(SESSION_ID).should eq "data"
    handler.write(SESSION_ID, "other data").should be_true
    handler.read(SESSION_ID).should eq "other data"
  end

  def test_create_does_not_overwrite_an_existing_session : Nil
    handler = self.create_handler

    handler.create(SESSION_ID, "data").should be_true
    handler.create(SESSION_ID, "other data").should be_false
    handler.read(SESSION_ID).should eq "data"
  end

  def test_update_does_not_create_a_session : Nil
    handler = self.create_handler

    handler.update(SESSION_ID, "data").should be_false
    handler.read(SESSION_ID).should eq ""
  end

  def test_write_does_not_bring_back_a_destroyed_session : Nil
    handler = self.existing_session

    handler.read(SESSION_ID).should eq "data"
    handler.destroy(SESSION_ID).should be_true
    handler.write(SESSION_ID, "other data").should be_false
    handler.read(SESSION_ID).should eq ""
  end

  def test_write_empty_data_destroys_the_session : Nil
    handler = self.existing_session

    handler.read(SESSION_ID).should eq "data"
    handler.write(SESSION_ID, "").should be_true
    handler.read(SESSION_ID).should eq ""
  end

  def test_destroy_new_session : Nil
    handler = self.create_handler

    handler.read(SESSION_ID).should eq ""
    handler.destroy(SESSION_ID).should be_true
  end

  def test_update_timestamp : Nil
    handler = self.existing_session

    handler.update_timestamp(SESSION_ID, "data").should be_true
    handler.read(SESSION_ID).should eq "data"
  end

  def test_update_timestamp_does_not_create_a_session : Nil
    handler = self.create_handler

    handler.update_timestamp(SESSION_ID, "data").should be_false
    handler.read(SESSION_ID).should eq ""
  end

  def test_update_timestamp_with_empty_data_destroys_the_session : Nil
    handler = self.existing_session

    handler.read(SESSION_ID).should eq "data"
    handler.update_timestamp(SESSION_ID, "").should be_true
    handler.read(SESSION_ID).should eq ""
  end

  def test_read_expired_session : Nil
    handler = self.create_handler max_lifetime: -1
    handler.create SESSION_ID, "data"

    handler.read(SESSION_ID).should eq ""
  end

  def test_gc : Nil
    handler = self.existing_session
    handler.create OTHER_SESSION_ID, "data"

    handler.gc(1440).should eq 0
    handler.gc(-1).should eq 2
    handler.read(SESSION_ID).should eq ""
    handler.read(OTHER_SESSION_ID).should eq ""
  end

  def test_close : Nil
    self.create_handler.close.should be_nil
  end

  private def existing_session : AHTTP::Session::Storage::Handler::AbstractHandler
    self.create_handler.tap &.create(SESSION_ID, "data")
  end
end
