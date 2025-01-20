require "./spec_helper"

struct RouterTest < ASPEC::TestCase
  def test_generate : Nil
    self.router.generate("foo").should eq "/foo"
    self.router.generate("foo", id: "1").should eq "/foo?id=1"
  end

  def test_match : Nil
    self.router.match("/foo").should eq({"_route" => "foo"})
    self.router.match(ART::Request.new "GET", "/bar").should eq({"_route" => "bar"})
  end

  def test_match? : Nil
    self.router.match?("/foo").should eq({"_route" => "foo"})
    self.router.match?(ART::Request.new "GET", "/bar").should eq({"_route" => "bar"})

    self.router.match?("/baz").should be_nil
    self.router.match?(ART::Request.new "GET", "/baz").should be_nil
  end

  private def router : ART::Router
    collection = ART::RouteCollection.new
    route1 = ART::Route.new "/foo"
    route2 = ART::Route.new "/bar"

    collection.add "foo", route1
    collection.add "bar", route2

    ART.compile collection

    router = ART::Router.new collection

    router.context = ART::RequestContext.new

    router
  end
end
