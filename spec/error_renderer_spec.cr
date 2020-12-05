require "./spec_helper"

describe ART::ErrorRenderer do
  it ART::Exceptions::HTTPException do
    exception = ART::Exceptions::TooManyRequests.new "cool your jets", 42

    renderer = ART::ErrorRenderer.new

    response = renderer.render exception

    response.headers.should eq HTTP::Headers{"retry-after" => "42", "content-type" => "application/json; charset=UTF-8"}
    response.status.should eq HTTP::Status::TOO_MANY_REQUESTS
    response.content.should eq %({"code":429,"message":"cool your jets"})
  end

  it ::Exception do
    exception = Exception.new "ERR"

    renderer = ART::ErrorRenderer.new

    response = renderer.render exception

    response.headers.should eq HTTP::Headers{"content-type" => "application/json; charset=UTF-8"}
    response.status.should eq HTTP::Status::INTERNAL_SERVER_ERROR
    response.content.should eq %({"code":500,"message":"Internal Server Error"})
  end
end
