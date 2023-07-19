require "../spec_helper"

struct RedirectControllerTest < ASPEC::TestCase
  def test_empty_route_permanent : Nil
    request = ATH::Request.new "GET", "/"
    controller = ATH::Controller::Redirect.new

    ex = expect_raises ATH::Exceptions::HTTPException do
      controller.redirect_url request, "", true
    end

    ex.status_code.should eq 410
  end

  def test_empty_route_non_permanent : Nil
    request = ATH::Request.new "GET", "/"
    controller = ATH::Controller::Redirect.new

    ex = expect_raises ATH::Exceptions::HTTPException do
      controller.redirect_url request, ""
    end

    ex.status_code.should eq 404
  end
end
