# Creates the `AHTTP::Session` of the current request, using the provided *storage_factory*.
class Athena::HTTP::Session::Factory
  # The optional *usage_reporter* is called each time the session is used, see `AHTTP::Session#usage_index`.
  def initialize(
    @request_store : AHTTP::RequestStore,
    @storage_factory : AHTTP::Session::Storage::FactoryInterface,
    @usage_reporter : Proc(Nil)? = nil,
  )
  end

  # Returns a new session for the current request.
  def create_session : AHTTP::Session
    AHTTP::Session.new @storage_factory.create_storage(@request_store.request?), usage_reporter: @usage_reporter
  end
end
