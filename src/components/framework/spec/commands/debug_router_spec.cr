require "../spec_helper"

struct DebugRouterCommandTest < ASPEC::TestCase
  @router : ART::Router

  def initialize
    routes = ART::RouteCollection.new
    routes.add "routerdebug_session_welcome", ART::Route.new "/session"
    routes.add "routerdebug_session_welcome_name", ART::Route.new "/session/{name}"
    routes.add "routerdebug_session_logout", ART::Route.new "/session_logout"
    routes.add "routerdebug_test", ART::Route.new "/test"

    @router = ART::Router.new routes
  end

  def test_all_routes : Nil
    tester = self.command_tester
    ret = tester.execute

    ret.should eq ACON::Command::Status::SUCCESS
    tester.display.should contain "routerdebug_session_welcome"
    tester.display.should contain "/session"

    tester.display.should contain "routerdebug_session_welcome_name"
    tester.display.should contain "/session/{name}"

    tester.display.should contain "routerdebug_session_logout"
    tester.display.should contain "/session_logout"

    tester.display.should contain "routerdebug_test"
    tester.display.should contain "/test"
  end

  def test_single_route : Nil
    tester = self.command_tester
    ret = tester.execute name: "routerdebug_session_welcome_name"

    ret.should eq ACON::Command::Status::SUCCESS
    tester.display.should contain "routerdebug_session_welcome_name"
    tester.display.should contain "/session/{name}"
  end

  def test_multiple_matching_routes : Nil
    tester = self.command_tester
    tester.inputs "3"
    ret = tester.execute name: "routerdebug", interactive: true

    ret.should eq ACON::Command::Status::SUCCESS
    tester.display.should contain "Select one of the matching routes:"
    tester.display.should contain "routerdebug_test"
    tester.display.should contain "/test"
  end

  def test_multiple_matching_routes_no_interaction : Nil
    tester = self.command_tester
    ret = tester.execute name: "routerdebug", interactive: false

    ret.should eq ACON::Command::Status::SUCCESS
    tester.display.should_not contain "Select one of the matching routes:"

    tester.display.should contain "routerdebug_session_welcome"
    tester.display.should contain "/session"

    tester.display.should contain "routerdebug_session_welcome_name"
    tester.display.should contain "/session/{name}"

    tester.display.should contain "routerdebug_session_logout"
    tester.display.should contain "/session_logout"

    tester.display.should contain "routerdebug_test"
    tester.display.should contain "/test"
  end

  def test_missing_route : Nil
    tester = self.command_tester

    expect_raises ACON::Exception::InvalidArgument, "The route 'blah' does not exist." do
      tester.execute name: "blah", interactive: true
    end
  end

  @[DataProvider("complete_provider")]
  def test_complete(input : Array(String), expected_suggestions : Array(String)) : Nil
    tester = ACON::Spec::CommandCompletionTester.new self.command
    suggestions = tester.complete input

    suggestions.should eq expected_suggestions
  end

  def complete_provider : Hash
    {
      "nothing" => {[] of String, ["routerdebug_session_welcome", "routerdebug_session_welcome_name", "routerdebug_session_logout", "routerdebug_test"]},
      "format"  => {["--format"], ["txt"]},
    }
  end

  private def command : ATH::Commands::DebugRouter
    ATH::Commands::DebugRouter.new(@router)
  end

  private def command_tester
    ACON::Spec::CommandTester.new self.command
  end
end
