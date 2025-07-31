require "../spec_helper"

private class MockFileParser < ATH::FileParser
  getter? parse_called : Bool = false
  getter? clear_called : Bool = false

  def parse(request : ATH::Request) : Nil
    @parse_called = true
  end

  def clear : Nil
    @clear_called = true
  end
end

describe ATH::Listeners::File do
  describe "#on_request" do
    it "no-ops when the request is not `multipart/form-data`" do
      ATH::Listeners::File.new(file_parser = MockFileParser.new(nil, 1, 0)).on_request new_request_event

      file_parser.parse_called?.should be_false
    end

    it "calls parse when the request is `multipart/form-data`" do
      ATH::Listeners::File
        .new(file_parser = MockFileParser.new(nil, 1, 0))
        .on_request new_request_event(
          headers: HTTP::Headers{
            "content-type" => "multipart/form-data",
          }
        )

      file_parser.parse_called?.should be_true
    end
  end

  describe "#on_terminate" do
    it "calls clear" do
      ATH::Listeners::File
        .new(file_parser = MockFileParser.new(nil, 1, 0))
        .on_terminate ATH::Events::Terminate.new new_request, ATH::Response.new

      file_parser.clear_called?.should be_true
    end
  end
end
