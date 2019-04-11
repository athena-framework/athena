require "./routing_spec_helper"

do_with_config do |client|
  describe Athena::Routing do
    it "should route correctly" do
      client.get("/calendar/events").body.should eq "\"events\""
      client.get("/calendar/external").body.should eq "\"calendars\""
    end

    describe "with a path param" do
      it "should route correctly" do
        client.get("/calendar/external/99999999").body.should eq "99999999"
      end
    end

    describe "that has parent prefixes" do
      it "should route correctly" do
        client.get("/calendar/athena/child1").body.should eq "\"child1 + athena\""
      end
    end
  end
end
