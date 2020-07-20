require "./spec_helper"

private class TestRouteResolver < ART::RouteResolver
  def initialize; end

  def build(&) : Nil
    with @router yield
  end
end

describe ART::RouteResolver do
  describe "#resolve" do
    it "resolves correctly" do
      resolver = TestRouteResolver.new
      route = new_action

      resolver.build do
        add "test", route
      end

      resolver.resolve(new_request).payload.should eq route
    end

    it "404s if a match could not be found" do
      resolver = TestRouteResolver.new

      expect_raises ART::Exceptions::NotFound, "No route found for 'GET /test'" do
        resolver.resolve new_request
      end
    end

    it "405s if no action is defined with that method" do
      resolver = TestRouteResolver.new

      resolver.build do
        add "test", new_action
      end

      expect_raises ART::Exceptions::MethodNotAllowed, "No route found for 'POST /test': (Allow: GET)" do
        resolver.resolve new_request method: "POST"
      end
    end
  end
end
