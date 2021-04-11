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
      response.headers.has_key?("date").should be_true
      response.headers.has_key?("cache-control").should be_true
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
    it "writes the data to the provided IO" do
      io = IO::Memory.new
      response = new_response io: io
      request = new_request

      ART::Response.new("DATA", 418, HTTP::Headers{"FOO" => "BAR"}).send request, response

      response.status.should eq HTTP::Status::IM_A_TEAPOT
      response.headers["foo"].should eq "BAR"
      response.headers["content-length"].should eq "4"
      response.headers.has_key?("date").should be_true
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
    it "sets content-type based on format" do
      request = ART::Request.new "GET", "/"
      request.request_format = "json"
      response = ART::Response.new "CONTENT"

      response.prepare request

      response.headers["content-type"].should eq "application/json"
    end

    it "does not override content-type if already set" do
      request = ART::Request.new "GET", "/"
      request.request_format = "json"
      response = ART::Response.new "CONTENT", headers: HTTP::Headers{"content-type" => "application/json; charset=UTF-8"}

      response.prepare request

      response.headers["content-type"].should eq "application/json; charset=UTF-8"
    end

    it "adds the charset to text based formats" do
      request = ART::Request.new "GET", "/"
      request.request_format = "csv"
      response = ART::Response.new "CONTENT"

      response.prepare request

      response.headers["content-type"].should eq "text/csv; charset=UTF-8"
    end

    it "allows customizing the charset" do
      request = ART::Request.new "GET", "/"
      request.request_format = "csv"
      response = ART::Response.new "CONTENT"
      response.charset = "ISO-8859-1"

      response.prepare request

      response.headers["content-type"].should eq "text/csv; charset=ISO-8859-1"
    end

    it "does not override the charset if already included" do
      request = ART::Request.new "GET", "/"
      request.request_format = "csv"
      response = ART::Response.new "CONTENT", headers: HTTP::Headers{"content-type" => "text/csv; charset=ISO-8859-1"}

      response.prepare request

      response.headers["content-type"].should eq "text/csv; charset=ISO-8859-1"
    end

    it "removes content for informational responses & empty responses" do
      request = ART::Request.new "GET", "/"
      response = ART::Response.new "CONTENT"

      response.headers["content-length"] = "5"
      response.headers["content-type"] = "text/plain"
      response.status = 101

      response.prepare request

      response.content.should be_empty
      response.headers.has_key?("content-length").should be_false
      response.headers.has_key?("content-type").should be_false
    end

    it "removes content for empty responses" do
      request = ART::Request.new "GET", "/"
      response = ART::Response.new "CONTENT"

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
      request = ART::Request.new "GET", "/"

      response = ART::Response.new "CONTENT"
      response.headers["content-length"] = "100"

      response.prepare request

      response.headers["content-length"].should eq "100"

      response.headers["transfer-encoding"] = "chunked"

      response.prepare request

      response.headers.has_key?("content-length").should be_false
    end

    it "removes content and preserves content-length for head requests" do
      response = ART::Response.new "CONTENT"
      request = ART::Request.new "HEAD", "/"
      response.headers["content-length"] = "5"

      response.prepare request

      response.content.should be_empty
      response.headers["content-length"].should eq "5"
    end

    it "sets pragma & expires headers on HTTP/1.0 request" do
      request = ART::Request.new "HEAD", "/", version: "HTTP/1.0"

      response = ART::Response.new "CONTENT"
      response.headers.add_cache_control_directive "no-cache"

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

    pending "cache-control" do
      it "sets cache-control if not already set" do
        request = ART::Request.new "GET", "/"

        response = ART::Response.new

        response.prepare request

        response.headers["cache-control"].should eq "private, no-cache"
      end

      it "sets the correct directive if last-modified header is included" do
        request = ART::Request.new "GET", "/"

        response = ART::Response.new headers: HTTP::Headers{"last-modified" => "MODIFIED"}

        response.prepare request

        response.headers["cache-control"].should eq "private, must-revalidate"
      end

      it "sets the correct directive if expires header is included" do
        request = ART::Request.new "GET", "/"

        response = ART::Response.new headers: HTTP::Headers{"expires" => "EXPIRES"}

        response.prepare request

        response.headers["cache-control"].should eq "private, must-revalidate"
      end

      it "does not override if already set" do
        request = ART::Request.new "GET", "/"

        response = ART::Response.new headers: HTTP::Headers{"cache-control" => "CACHE"}
        response.headers["cache-control"].should eq "CACHE"

        response.prepare request

        response.headers["cache-control"].should eq "CACHE"
      end
    end

    pending "date" do
      it "sets date if not set" do
        request = ART::Request.new "GET", "/"

        response = ART::Response.new
        response.headers.has_key?("date").should be_false

        response.prepare request

        response.headers.has_key?("date").should be_true
      end

      it "does not override if already present" do
        request = ART::Request.new "GET", "/"

        response = ART::Response.new headers: HTTP::Headers{"date" => "DATE"}
        response.headers["date"].should eq "DATE"

        response.prepare request

        response.headers["date"].should eq "DATE"
      end

      it "does not set a date if informational response" do
        request = ART::Request.new "GET", "/"

        response = ART::Response.new status: HTTP::Status::CONTINUE
        response.headers.has_key?("date").should be_false

        response.prepare request

        response.headers.has_key?("date").should be_false
      end
    end
  end

  it "#set_public" do
    response = ART::Response.new
    response.set_public

    response.headers["cache-control"].should contain "public"
    response.headers["cache-control"].should_not contain "private"
  end

  describe "#set_etag" do
    it "sets the etag" do
      response = ART::Response.new
      response.set_etag "ETAG"
      response.etag.should eq %("ETAG")
    end

    it "removes the etag if value is `nil`" do
      response = ART::Response.new headers: HTTP::Headers{"etag" => "ETAG"}
      response.set_etag nil
      response.etag.should be_nil
    end

    it "allows setting a weak etag" do
      response = ART::Response.new
      response.set_etag "ETAG", true
      response.etag.should eq %(W/"ETAG")
    end
  end

  describe "#last_modified=" do
    it "sets the last-modified header" do
      now = Time.utc

      response = ART::Response.new
      response.last_modified = now
      response.last_modified.should eq now.at_beginning_of_second
    end

    it "removes the header if the value is `nil`" do
      response = ART::Response.new headers: HTTP::Headers{"last-modified" => "TIME"}
      response.last_modified = nil
      response.last_modified.should be_nil
    end
  end
end
