require "./handler_test_case"

struct AHTTP::Session::Storage::Handler::NullTest < ASPEC::TestCase
  def test_nothing_is_persisted : Nil
    handler = AHTTP::Session::Storage::Handler::Null.new

    handler.read("0123456789abcdef0123456789abcdef").should eq ""
    handler.write("0123456789abcdef0123456789abcdef", "data").should be_true
    handler.update_timestamp("0123456789abcdef0123456789abcdef", "data").should be_true
    handler.read("0123456789abcdef0123456789abcdef").should eq ""
  end

  def test_update_existing_session : Nil
    handler = AHTTP::Session::Storage::Handler::Null.new

    handler.update("0123456789abcdef0123456789abcdef", "data").should be_true
    handler.destroy("0123456789abcdef0123456789abcdef").should be_true
  end

  def test_update_timestamp_with_empty_data_destroys_the_session : Nil
    AHTTP::Session::Storage::Handler::Null.new.update_timestamp("0123456789abcdef0123456789abcdef", "").should be_true
  end

  def test_gc : Nil
    AHTTP::Session::Storage::Handler::Null.new.gc(1440).should eq 0
  end
end
