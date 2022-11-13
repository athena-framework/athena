require "../spec_helper"
require "./abstract_url_matcher_test_case"

struct TraceableURLMatcherTest < AbstractURLMatcherTestCase
  private def get_matcher(routes : ART::RouteCollection, context : ART::RequestContext = ART::RequestContext.new) : ART::Matcher::URLMatcher
    ART::Matcher::TraceableURLMatcher.new routes, context
  end

  def test_traces : Nil
    condition_route = ART::Route.new "/foo2", host: "baz"
    condition_route.condition do |ctx|
      "GET" == ctx.method
    end

    routes = self.build_collection do
      add "foo", ART::Route.new "/foo", methods: "POST"
      add "bar", ART::Route.new "/bar/{id}", requirements: {"id" => /\d+/}
      add "bar1", ART::Route.new "/bar/{name}", requirements: {"id" => /\w+/}, methods: "POST"
      add "bar2", ART::Route.new "/foo", host: "baz"
      add "bar3", ART::Route.new "/foo1", host: "baz"
      add "bar4", condition_route
    end

    context = ART::RequestContext.new host: "baz"

    matcher = ART::Matcher::TraceableURLMatcher.new routes, context

    traces = matcher.traces("/babar")
    self.get_levels(traces).should eq [0, 0, 0, 0, 0, 0]

    traces = matcher.traces("/foo")
    self.get_levels(traces).should eq [1, 0, 0, 2]

    traces = matcher.traces("/bar/12")
    self.get_levels(traces).should eq [0, 2]

    traces = matcher.traces("/bar/dd")
    self.get_levels(traces).should eq [0, 1, 1, 0, 0, 0]

    traces = matcher.traces("/foo1")
    self.get_levels(traces).should eq [0, 0, 0, 0, 2]

    context.method = "POST"

    traces = matcher.traces("/foo")
    self.get_levels(traces).should eq [2]

    traces = matcher.traces("/bar/dd")
    self.get_levels(traces).should eq [0, 1, 2]

    # Test Request overload (method is set via context)
    traces = matcher.traces(HTTP::Request.new "GET", "/bar/dd")
    self.get_levels(traces).should eq [0, 1, 2]

    traces = matcher.traces("/foo2")
    self.get_levels(traces).should eq [0, 0, 0, 0, 0, 1]
  end

  def test_traces_match_route_on_multiple_hosts : Nil
    routes = self.build_collection do
      add "first", ART::Route.new "/mypath/", {"_controller" => "SomeController#first"}, host: "some.example.com"
      add "second", ART::Route.new "/mypath/", {"_controller" => "SomeController#second"}, host: "another.example.com"
    end

    context = ART::RequestContext.new host: "baz"

    matcher = ART::Matcher::TraceableURLMatcher.new routes, context

    traces = matcher.traces("/mypath/")
    self.get_levels(traces).should eq [1, 1]
  end

  private def get_levels(traces : Array(ART::Matcher::TraceableURLMatcher::Trace)) : Array(Int32)
    traces.map &.level.value
  end

  private def build_collection(&) : ART::RouteCollection
    routes = ART::RouteCollection.new

    with routes yield

    routes
  end
end
