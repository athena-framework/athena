require "../../spec_helper"

struct ORMControllerTest < ATH::Spec::APITestCase
  def test_releases_the_connection_once_the_request_is_done : Nil
    released = MockConnection.released

    self.get "/orm/transaction"

    self.assert_response_is_successful
    MockConnection.released.should eq released + 1
  end
end
