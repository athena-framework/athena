require "./spec_helper"

struct AHTTP::RequestStoreTest < ASPEC::TestCase
  def test_session : Nil
    session = AHTTP::Session.new AHTTP::Session::Storage.new AHTTP::Session::Storage::Handler::Memory.new
    request = AHTTP::Request.new "GET", "/"
    request.session = session

    store = AHTTP::RequestStore.new
    store.request = request

    store.session.should be session
  end

  def test_session_without_a_request : Nil
    expect_raises AHTTP::Exception::SessionNotFound, "There is currently no session available." do
      AHTTP::RequestStore.new.session
    end
  end

  def test_session_without_a_session : Nil
    store = AHTTP::RequestStore.new
    store.request = AHTTP::Request.new "GET", "/"

    expect_raises AHTTP::Exception::SessionNotFound, "There is currently no session available." do
      store.session
    end
  end
end
