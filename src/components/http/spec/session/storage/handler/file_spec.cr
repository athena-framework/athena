require "./handler_test_case"

struct AHTTP::Session::Storage::Handler::FileTest < HandlerTestCase
  @save_path : String

  def initialize
    @save_path = ::File.tempname "athena_sessions"
  end

  def tear_down : Nil
    FileUtils.rm_rf @save_path
  end

  def create_handler(max_lifetime : Int32 = 1440) : AHTTP::Session::Storage::Handler::AbstractHandler
    AHTTP::Session::Storage::Handler::File.new @save_path, max_lifetime
  end

  def test_creates_the_save_path : Nil
    save_path = ::File.join @save_path, "nested", "sessions"

    AHTTP::Session::Storage::Handler::File.new(save_path).save_path.should eq save_path
    Dir.exists?(save_path).should be_true
  end

  def test_stores_each_session_in_its_own_private_file : Nil
    self.create_handler.create SESSION_ID, "data"

    Dir.children(@save_path).should eq ["sess_#{SESSION_ID}"]

    {% unless flag? :windows %}
      ::File.info(self.session_path).permissions.should eq ::File::Permissions.new(0o600)
    {% end %}
  end

  def test_read_session_not_used_within_max_lifetime : Nil
    handler = self.create_handler
    handler.create SESSION_ID, "data"

    ::File.utime Time.utc - 1441.seconds, Time.utc - 1441.seconds, self.session_path

    handler.read(SESSION_ID).should eq ""
  end

  def test_update_timestamp_updates_the_modification_time : Nil
    handler = self.create_handler
    handler.create SESSION_ID, "data"

    ::File.utime Time.utc - 1000.seconds, Time.utc - 1000.seconds, self.session_path
    handler.update_timestamp SESSION_ID, "data"

    ::File.info(self.session_path).modification_time.should be_close Time.utc, 5.seconds
  end

  def test_gc_ignores_other_files : Nil
    handler = self.create_handler
    ::File.write ::File.join(@save_path, "other"), "data"

    handler.gc(-1).should eq 0
    ::File.exists?(::File.join(@save_path, "other")).should be_true
  end

  def test_rejects_invalid_session_ids : Nil
    expect_raises AHTTP::Exception::InvalidArgument, "Invalid session ID." do
      self.create_handler.read "../../etc/passwd"
    end
  end

  private def session_path : String
    ::File.join @save_path, "sess_#{SESSION_ID}"
  end
end
