require "./routing_spec_helper"

describe Athena::Routing do
  run_server

  it "is concurrently safe", focus: true do
    spawn do
      sleep 1
      CLIENT.get("/get/safe?bar").body.should eq %("safe")
    end
    CLIENT.get("/get/safe?foo").body.should eq %("safe")
  end
end
