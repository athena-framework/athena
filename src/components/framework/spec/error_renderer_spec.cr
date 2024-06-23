require "./spec_helper"

private class MockException < ::Exception
  def initialize(@first_line : String)
    super "ERR"
  end

  def backtrace? : Array(String)
    [@first_line]
  end
end

describe ATH::ErrorRenderer do
  it ATH::Exception::HTTPException do
    exception = ATH::Exception::TooManyRequests.new "cool your jets", 42

    renderer = ATH::ErrorRenderer.new false

    response = renderer.render exception

    response.headers["retry-after"].should eq "42"
    response.headers["content-type"].should eq "application/json; charset=utf-8"
    response.status.should eq HTTP::Status::TOO_MANY_REQUESTS
    response.content.should eq %({"code":429,"message":"cool your jets"})
  end

  it ::Exception do
    exception = Exception.new "ERR"

    renderer = ATH::ErrorRenderer.new false

    response = renderer.render exception

    response.headers["content-type"].should eq "application/json; charset=utf-8"
    response.headers["x-debug-exception-message"]?.should be_nil
    response.headers["x-debug-exception-class"]?.should be_nil
    response.headers["x-debug-exception-file"]?.should be_nil
    response.headers["x-debug-exception-code"]?.should be_nil
    response.status.should eq HTTP::Status::INTERNAL_SERVER_ERROR
    response.content.should eq %({"code":500,"message":"Internal Server Error"})
  end

  describe "debug mode" do
    it "line + column" do
      path = Path["src", "components", "framework", "spec", "error_renderer_spec.cr"]
      exception = MockException.new "#{path}:10:20"

      renderer = ATH::ErrorRenderer.new true

      response = renderer.render exception

      response.headers["content-type"].should eq "application/json; charset=utf-8"
      response.headers["x-debug-exception-message"].should eq "ERR"
      response.headers["x-debug-exception-class"].should eq "MockException"
      response.headers["x-debug-exception-file"].should match /#{URI.encode_path path.to_s}:\d+:\d+$/
      response.headers["x-debug-exception-code"].should eq "500"
      response.status.should eq HTTP::Status::INTERNAL_SERVER_ERROR
      response.content.should eq %({"code":500,"message":"Internal Server Error"})
    end

    it "only line" do
      path = Path["src", "components", "framework", "spec", "error_renderer_spec.cr"]
      exception = MockException.new "#{path}:10"

      renderer = ATH::ErrorRenderer.new true

      response = renderer.render exception

      response.headers["content-type"].should eq "application/json; charset=utf-8"
      response.headers["x-debug-exception-message"].should eq "ERR"
      response.headers["x-debug-exception-class"].should eq "MockException"
      response.headers["x-debug-exception-file"].should match /#{URI.encode_path path.to_s}:\d+$/
      response.headers["x-debug-exception-code"].should eq "500"
      response.status.should eq HTTP::Status::INTERNAL_SERVER_ERROR
      response.content.should eq %({"code":500,"message":"Internal Server Error"})
    end
  end
end
