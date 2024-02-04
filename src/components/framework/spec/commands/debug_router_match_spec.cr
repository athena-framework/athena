require "../spec_helper"

struct DebugRouterMatchCommandTest < ASPEC::TestCase
  def test_matches : Nil
    tester = self.command_tester
    ret = tester.execute path_info: "/foo", decorated: false

    ret.should eq ACON::Command::Status::SUCCESS
    tester.display.should contain "Route Name   | foo"
  end

  def test_no_match : Nil
    tester = self.command_tester
    ret = tester.execute path_info: "/test", decorated: false

    ret.should eq ACON::Command::Status::FAILURE
    tester.display(true).should contain "None of the routes match the path '/test'"
  end

  def test_partial : Nil
    tester = self.command_tester
    ret = tester.execute path_info: "/bar/11", decorated: false

    ret.should eq ACON::Command::Status::FAILURE
    tester.display.should contain "Route 'bar' almost matches but requirement for 'id' does not match (10)"
    tester.display.should contain "None of the routes match the path '/bar/11'"
  end

  private def command_tester : ACON::Spec::CommandTester
    application = ACON::Application.new "Athena Specs"
    application.add ATH::Commands::DebugRouterMatch.new self.router
    application.add ATH::Commands::DebugRouter.new self.router

    ACON::Spec::CommandTester.new application.find "debug:router:match"
  end

  private def router : ART::RouterInterface
    route_collection = ART::RouteCollection.new
    route_collection.add "foo", ART::Route.new "foo"
    route_collection.add "bar", ART::Route.new "/bar/{id<10>}"

    context = ART::RequestContext.new

    ART::Router.new route_collection, context: context
  end
end
