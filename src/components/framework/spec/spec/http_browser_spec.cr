require "../spec_helper"

@[ADI::Register]
class HTTPBrowserResettable
  include ACTR::Service::Resettable

  class_getter resets = 0

  def reset : Nil
    @@resets += 1
  end
end

@[ADI::Register]
class HTTPBrowserCloseable
  include ACTR::Service::Closeable

  class_getter closes = 0

  def close : Nil
    @@closes += 1
  end
end

struct HTTPBrowserTest < ATH::Spec::APITestCase
  def test_resets_resettable_services_once_the_request_is_done : Nil
    resets = HTTPBrowserResettable.resets

    self.get "/test"

    self.assert_response_is_successful
    HTTPBrowserResettable.resets.should eq resets + 1
  end

  # The requests of a test share its container, so the test closes its services once it's done.
  def test_leaves_closeable_services_open_once_the_request_is_done : Nil
    closes = HTTPBrowserCloseable.closes

    self.get "/test"

    self.assert_response_is_successful
    HTTPBrowserCloseable.closes.should eq closes
  end
end
