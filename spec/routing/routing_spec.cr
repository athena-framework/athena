require "./routing_spec_helper"

describe Athena::Routing do
  run_server

  it "is concurrently safe" do
    spawn do
      sleep 1
      HTTP::Client.get("http://localhost:3000/get/safe?bar").body.should eq %("safe")
    end
    CLIENT.get("/get/safe?foo").body.should eq %("safe")
  end

  it "404s if a route doesn't exist" do
    response = CLIENT.get("/fake/route")
    response.status.should eq HTTP::Status::NOT_FOUND
    response.body.should eq %({"code":404,"message":"No route found for 'GET /fake/route'"})
  end
end
