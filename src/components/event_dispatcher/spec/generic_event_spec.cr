require "./spec_helper"

struct GenericEventTest < ASPEC::TestCase
  def test_with_arguments : Nil
    event = AED::GenericEvent(String, Int32 | String).new(
      "foo",
      args = {"counter" => 0, "data" => "bar"}
    )

    event.subject.should eq "foo"
    event.arguments.should eq args
    event.arguments = {"counter" => 2} of String => Int32 | String
    event.arguments.should eq({"counter" => 2})

    event["counter"].should eq 2
    event["foo"]?.should be_nil
    event["counter"] = 5
    event["counter"].should eq 5
    event.has_key?("counter").should be_true
  end

  def test_without_arguments : Nil
    event = AED::GenericEvent.new "foo"
    event.subject.should eq "foo"
    event.arguments.should be_empty
  end
end
