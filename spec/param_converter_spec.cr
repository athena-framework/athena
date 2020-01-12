require "./spec_helper"

describe Athena::Routing::ParamConverter do
  run_server

  it "should convert path parameters" do
    CLIENT.get("/double/2").body.should eq "4"
  end

  it "should convert request parameters" do
    CLIENT.get("/double-query?num=3").body.should eq "6"
  end

  it "should be able to process request bodies" do
    CLIENT.post("/user", body: {name: "Jim", id: 1}.to_json).body.should eq "1"
  end
end
