require "./spec_helper"

private struct TestWriter < ART::Response::Writer
  def write(output : IO, & : IO -> Nil) : Nil
    yield output
    output.print "EOF"
  end
end

describe ART::Response do
  describe ".new" do
    it "defaults" do
      response = ART::Response.new
      response.headers.should be_empty
      response.content.should be_empty
      response.status.should eq HTTP::Status::OK
    end

    it "accepts an Int status" do
      ART::Response.new(status: 201).status.should eq HTTP::Status::CREATED
    end

    it "accepts an HTTP::Status status" do
      ART::Response.new(status: HTTP::Status::CREATED).status.should eq HTTP::Status::CREATED
    end

    it "accepts string content" do
      ART::Response.new("FOO").content.should eq "FOO"
    end

    it "accepts nil content" do
      ART::Response.new(nil).content.should eq ""
    end
  end

  describe "#content=" do
    it "accepts a string" do
      response = ART::Response.new "FOO"
      response.content.should eq "FOO"
      response.content = "BAR"
      response.content.should eq "BAR"
    end
  end

  describe "#send" do
    it "sends the response to the client" do
      io = IO::Memory.new
      response = new_response io: io
      request = new_request

      ART::Response.new("DATA", 418, HTTP::Headers{"FOO" => "BAR"}).send HTTP::Server::Context.new request, response

      response.status.should eq HTTP::Status::IM_A_TEAPOT
      response.headers.should eq HTTP::Headers{"FOO" => "BAR", "content-length" => "4"}
      response.closed?.should be_true

      io.rewind.gets_to_end.should end_with "DATA"
    end
  end

  describe "#status=" do
    it "accepts an Int" do
      response = ART::Response.new
      response.status = 201
      response.status.should eq HTTP::Status::CREATED
    end

    it "accepts an HTTP::Status" do
      response = ART::Response.new
      response.status = HTTP::Status::CREATED
      response.status.should eq HTTP::Status::CREATED
    end
  end

  describe "#write" do
    it "writes the content to the given output IO" do
      io = IO::Memory.new
      ART::Response.new("FOO BAR").write io

      io.to_s.should eq "FOO BAR"
    end

    it "supports customization via an ART::Response::Writer" do
      io = IO::Memory.new
      response = ART::Response.new("FOO BAR")

      response.writer = TestWriter.new
      response.write io

      io.to_s.should eq "FOO BAREOF"
    end
  end

  describe "#prepare" do
    it "removes content for head requests" do
      response = ART::Response.new "CONTENT"
      request = HTTP::Request.new "HEAD", "/"
      response.headers["content-length"] = "5"

      response.prepare request

      response.content.should be_empty
      response.headers["content-length"].should eq "5"
    end

    it "removes content for informational & empty responses" do
      request = HTTP::Request.new "GET", "/"

      response = ART::Response.new "CONTENT"
      response.headers["content-length"] = "5"
      response.headers["content-type"] = "text/plain"
      response.status = 101

      response.prepare request

      response.content.should be_empty
      response.headers.has_key?("content-length").should be_false
      response.headers.has_key?("content-type").should be_false

      response.content = "CONTENT"
      response.headers["content-length"] = "5"
      response.headers["content-type"] = "text/plain"
      response.status = 204

      response.prepare request

      response.content.should be_empty
      response.headers.has_key?("content-length").should be_false
      response.headers.has_key?("content-type").should be_false
    end

    it "removes content-length if transfer-encoding is set" do
      request = HTTP::Request.new "GET", "/"

      response = ART::Response.new "CONTENT"
      response.headers["content-length"] = "100"

      response.prepare request

      response.headers["content-length"].should eq "100"

      response.headers["transfer-encoding"] = "chunked"

      response.prepare request

      response.headers.has_key?("content-length").should be_false
    end

    it "sets pragma & expires headers on HTTP/1.0 request" do
      request = HTTP::Request.new "HEAD", "/", version: "HTTP/1.0"

      response = ART::Response.new "CONTENT"
      response.headers["cache-control"] = "no-cache"

      response.prepare request

      response.content.should be_empty
      response.headers["pragma"]?.should eq "no-cache"
      response.headers["expires"]?.should eq "-1"

      request.version = "HTTP/1.1"
      response = ART::Response.new "CONTENT"

      response.prepare request

      response.headers.has_key?("pragma").should be_false
      response.headers.has_key?("expires").should be_false
    end
  end
end
