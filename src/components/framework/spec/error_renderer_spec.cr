require "./spec_helper"

describe ATH::ErrorRenderer do
  it ATH::Exceptions::HTTPException do
    exception = ATH::Exceptions::TooManyRequests.new "cool your jets", 42

    renderer = ATH::ErrorRenderer.new false

    response = renderer.render exception

    response.headers["retry-after"].should eq "42"
    response.headers["content-type"].should eq "application/json; charset=UTF-8"
    response.status.should eq HTTP::Status::TOO_MANY_REQUESTS
    response.content.should eq %({"code":429,"message":"cool your jets"})
  end

  it ::Exception do
    exception = Exception.new "ERR"

    renderer = ATH::ErrorRenderer.new false

    response = renderer.render exception

    response.headers["content-type"].should eq "application/json; charset=UTF-8"
    response.headers["x-debug-exception-message"]?.should be_nil
    response.headers["x-debug-exception-class"]?.should be_nil
    response.headers["x-debug-exception-file"]?.should be_nil
    response.headers["x-debug-exception-code"]?.should be_nil
    response.status.should eq HTTP::Status::INTERNAL_SERVER_ERROR
    response.content.should eq %({"code":500,"message":"Internal Server Error"})
  end

  it "when in debug mode" do
    exception = uninitialized Exception

    begin
      raise Exception.new "ERR"
    rescue exception
    end

    renderer = ATH::ErrorRenderer.new true

    response = renderer.render exception

    response.headers["content-type"].should eq "application/json; charset=UTF-8"
    response.headers["x-debug-exception-message"].should eq "ERR"
    response.headers["x-debug-exception-class"].should eq "Exception"
    response.headers["x-debug-exception-file"].should match /src\/components\/framework\/spec\/error_renderer_spec\.cr:\d+:\d+/
    response.headers["x-debug-exception-code"].should eq "500"
    response.status.should eq HTTP::Status::INTERNAL_SERVER_ERROR
    response.content.should eq %({"code":500,"message":"Internal Server Error"})
  end
end
