require "./spec_helper"

struct RoutingTest < ATH::Spec::APITestCase
  def test_controller_with_prefix : Nil
    self.get "/prefix/index"

    self.assert_response_is_successful
  end
end
