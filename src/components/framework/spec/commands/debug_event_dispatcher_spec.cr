require "../spec_helper"

private class MyEvent < AED::Event; end

private class MyOtherEvent < AED::Event; end

struct DebugEventDispatcherCommandTest < ASPEC::TestCase
  def test_specific_event : Nil
    tester = self.command_tester
    ret = tester.execute event: "MyEvent", decorated: false

    ret.should eq ACON::Command::Status::SUCCESS
    tester.display.should contain "Registered Listeners for the MyEvent Event"
    tester.display.should contain "#1      unknown callable           0"
    tester.display.should contain "#2      some_service#some_method   -1"

    tester.display.should_not contain "GenericEvent"
  end

  def test_specific_event_no_match : Nil
    tester = self.command_tester
    ret = tester.execute event: "blah", decorated: false, capture_stderr_separately: true

    ret.should eq ACON::Command::Status::SUCCESS
    tester.display.should be_empty
    tester.error_output(true).should contain "[WARNING] The event 'blah' does not have any registered listeners."
  end

  def test_specific_event_partial_match_single : Nil
    tester = self.command_tester
    ret = tester.execute event: "other", decorated: false

    ret.should eq ACON::Command::Status::SUCCESS
    tester.display.should contain "Registered Listeners for the MyOtherEvent Event"
    tester.display.should contain "#1      unknown callable   0"

    tester.display.should_not contain "MyEvent"
    tester.display.should_not contain "GenericEvent"
  end

  def test_specific_event_partial_match_multiple : Nil
    tester = self.command_tester
    ret = tester.execute event: "my", decorated: false

    ret.should eq ACON::Command::Status::SUCCESS
    tester.display.should contain "Registered Listeners Grouped by Event"

    tester.display.should contain "MyEvent event"
    tester.display.should contain "#1      unknown callable           0"
    tester.display.should contain "#2      some_service#some_method   -1"

    tester.display.should contain "MyOtherEvent event"
    tester.display.should contain "#1      unknown callable   0"

    tester.display.should_not contain "GenericEvent"
  end

  def test_all_events : Nil
    tester = self.command_tester
    ret = tester.execute decorated: false

    ret.should eq ACON::Command::Status::SUCCESS
    tester.display.should contain "Registered Listeners Grouped by Event"

    tester.display.should contain "MyEvent event"
    tester.display.should contain "#1      unknown callable           0"
    tester.display.should contain "#2      some_service#some_method   -1"

    tester.display.should contain "MyOtherEvent event"
    tester.display.should contain "#1      unknown callable   0"

    tester.display.should contain "Athena::EventDispatcher::GenericEvent(String, String) event"
    tester.display.should contain "#1      generic-event   0"
  end

  @[DataProvider("complete_provider")]
  def test_complete(input : Array(String), expected_suggestions : Array(String)) : Nil
    tester = ACON::Spec::CommandCompletionTester.new self.command
    suggestions = tester.complete input

    suggestions.should eq expected_suggestions
  end

  def complete_provider : Hash
    {
      "nothing" => {[] of String, ["Athena::EventDispatcher::GenericEvent(String, String)", "MyEvent", "MyOtherEvent"]},
      "format"  => {["--format"], ["txt"]},
    }
  end

  private def command : ATH::Commands::DebugEventDispatcher
    ATH::Commands::DebugEventDispatcher.new self.dispatcher
  end

  private def command_tester : ACON::Spec::CommandTester
    ACON::Spec::CommandTester.new self.command
  end

  private def dispatcher : AED::EventDispatcherInterface
    dispatcher = AED::EventDispatcher.new
    dispatcher.listener(AED::GenericEvent(String, String), name: "generic-event") { }
    dispatcher.listener(MyEvent) { }
    dispatcher.listener(MyEvent, priority: -1, name: "some_service#some_method") { }
    dispatcher.listener(MyOtherEvent) { }

    dispatcher
  end
end
