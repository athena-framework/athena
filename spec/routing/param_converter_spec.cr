require "./routing_spec_helper"

describe Athena::Routing::Converters::Converter do
  run_server

  describe :path do
    it "should return the converted value" do
      CLIENT.get("/double/2").body.should eq "4"
    end
  end

  describe :query do
    it "should return the converted value" do
      CLIENT.get("/double-query?num=3").body.should eq "6"
    end
  end
end
