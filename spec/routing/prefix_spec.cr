require "./routing_spec_helper"

describe Athena::Routing do
  run_server

  it "should route correctly" do
    CLIENT.get("/calendar/events").body.should eq %("events")
    CLIENT.get("/calendar/external").body.should eq %("calendars")
  end

  describe "with a path param" do
    it "should route correctly" do
      CLIENT.get("/calendar/external/99999999").body.should eq "99999999"
    end
  end

  describe "that has parent prefixes" do
    it "should route correctly" do
      CLIENT.get("/calendar/athena/child1").body.should eq %("child1 + athena")
    end
  end
end
