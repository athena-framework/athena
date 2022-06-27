require "./spec_helper"

private class MockURLMatcher
  include Athena::Routing::Matcher::RequestMatcherInterface
  include Athena::Routing::Matcher::URLMatcherInterface

  property context : ART::RequestContext

  def initialize(@route : String, @exception : Exception? = nil)
    @context = ART::RequestContext.new
  end

  # :inherit:
  def match(path : String) : Hash(String, String?)
    if ex = @exception
      raise ex
    end

    {
      "_route" => @route,
    } of String => String?
  end

  def match?(path : String) : Hash(String, String?)?
  end

  # :inherit:
  def match?(@request : ART::Request) : Hash(String, String?)?
    self.match? @request.not_nil!.path
  ensure
    @request = nil
  end

  # :inherit:
  def match(@request : ART::Request) : Hash(String, String?)
    self.match @request.not_nil!.path
  ensure
    @request = nil
  end
end

describe ART::RoutingHandler do
  describe "#add" do
    it "raises when trying to add another collection" do
      expect_raises ArgumentError, "Cannot add an existing collection to a routing handler." do
        ART::RoutingHandler.new.add ART::RouteCollection.new
      end
    end

    it "captures the provided route" do
      handler = ART::RoutingHandler.new
      handler.add "a_route", ART::Route.new "/foo"
      handler.size.should eq 1
    end
  end

  describe "#call" do
    it "happy path" do
      value = 0

      handler = ART::RoutingHandler.new MockURLMatcher.new "foo"

      handler.add "foo", ART::Route.new "/foo" do |ctx, params|
        ctx.request.method.should eq "GET"
        ctx.request.path.should eq "/foo"
        value += 10
        params.should eq({"_route" => "foo"})
      end

      handler.call HTTP::Server::Context.new HTTP::Request.new("GET", "/foo"), HTTP::Server::Response.new(IO::Memory.new)

      value.should eq 10
    end

    it "missing route" do
      handler = ART::RoutingHandler.new MockURLMatcher.new "foo", ART::Exception::ResourceNotFound.new "Missing"
      handler.add("foo", ART::Route.new("/foo")) { }

      handler.call HTTP::Server::Context.new HTTP::Request.new("GET", "/foo"), resp = HTTP::Server::Response.new(IO::Memory.new)

      resp.status.should eq HTTP::Status::NOT_FOUND
    end

    it "unsupported method" do
      handler = ART::RoutingHandler.new MockURLMatcher.new "foo", ART::Exception::MethodNotAllowed.new ["PUT", "SEARCH"], "Not Allowed"
      handler.add("foo", ART::Route.new("/foo")) { }

      handler.call HTTP::Server::Context.new HTTP::Request.new("GET", "/foo"), resp = HTTP::Server::Response.new(IO::Memory.new)

      resp.status.should eq HTTP::Status::METHOD_NOT_ALLOWED
    end
  end

  describe "#compile" do
    it "compiles the wrapped collection" do
      handler = ART::RoutingHandler.new
      handler.add "a_route", ART::Route.new "/foo"
      handler.compile
      ART::RouteProvider.static_routes.size.should eq 1
    end
  end
end
