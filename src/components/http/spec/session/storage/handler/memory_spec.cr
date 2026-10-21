require "./handler_test_case"

struct AHTTP::Session::Storage::Handler::MemoryTest < HandlerTestCase
  def create_handler(max_lifetime : Int32 = 1440) : AHTTP::Session::Storage::Handler::AbstractHandler
    AHTTP::Session::Storage::Handler::Memory.new max_lifetime
  end
end
