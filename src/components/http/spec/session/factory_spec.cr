require "../spec_helper"

private class RecordingStorageFactory
  include AHTTP::Session::Storage::FactoryInterface

  getter requests = [] of AHTTP::Request?

  def create_storage(request : AHTTP::Request?) : AHTTP::Session::Storage::Interface
    @requests << request

    AHTTP::Session::Storage.new AHTTP::Session::Storage::Handler::Memory.new
  end
end

struct AHTTP::Session::FactoryTest < ASPEC::TestCase
  def test_create_session : Nil
    request = AHTTP::Request.new "GET", "/"
    request_store = AHTTP::RequestStore.new
    request_store.request = request

    storage_factory = RecordingStorageFactory.new
    reports = 0

    session = AHTTP::Session::Factory.new(request_store, storage_factory, -> { reports += 1; nil }).create_session
    session.has? "foo"

    storage_factory.requests.should eq [request]
    reports.should eq 1
  end

  def test_create_session_without_a_request : Nil
    storage_factory = RecordingStorageFactory.new

    AHTTP::Session::Factory.new(AHTTP::RequestStore.new, storage_factory).create_session

    storage_factory.requests.should eq [nil]
  end
end
