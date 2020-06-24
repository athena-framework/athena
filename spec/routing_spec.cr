require "./spec_helper"

describe Athena::Routing do
  run_server

  it "is concurrently safe" do
    spawn do
      sleep 1
      CLIENT.get("/get/safe?bar").body.should eq %("safe")
    end
    CLIENT.get("/get/safe?foo").body.should eq %("safe")
  end

  it "creates a new container on each request with keep-alive connection" do
    client = HTTP::Client.new "localhost", 3000

    response1 = client.get("/container/id", headers: HTTP::Headers{"connection" => "keep-alive"}).body
    response2 = client.get("/container/id", headers: HTTP::Headers{"connection" => "keep-alive"}).body
    response1.should_not eq response2
  end

  it "404s if a route doesn't exist" do
    response = CLIENT.get("/fake/route")
    response.status.should eq HTTP::Status::NOT_FOUND
    response.body.should eq %({"code":404,"message":"No route found for 'GET /fake/route'"})
  end

  it "allows returning an ART::Response" do
    response = CLIENT.get("/art/response")
    response.status.should eq HTTP::Status::IM_A_TEAPOT
    response.headers["content-type"].should eq "BAR"
    response.body.should eq "FOO"
  end

  it "supports redirection" do
    response = CLIENT.get("/art/redirect")
    response.status.should eq HTTP::Status::FOUND
    response.headers["location"].should eq "https://crystal-lang.org"
    response.body.should be_empty
  end

  it "supports custom HTTP method endpoints" do
    CLIENT.exec("FOO", "/custom-method").body.should eq %("FOO")
  end

  describe ART::ParamConverter do
    it "works with a query param" do
      CLIENT.get "/events"
      CLIENT.get "/events?since=2020-04-08T12:34:56Z"
    end
  end

  describe "macro DSL" do
    it "nil return type results in 204" do
      response = CLIENT.get "/macro/get-nil"
      response.body.should be_empty
      response.status.should eq HTTP::Status::NO_CONTENT
    end

    it "works with arguments" do
      CLIENT.get("/macro/add/50/25").body.should eq "75"
    end

    it "works with GET endpoints" do
      response = CLIENT.get("/macro")
      response.body.should eq %("GET")
      response.status.should eq HTTP::Status::OK
    end

    it "adds a HEAD route for GET requests" do
      response = CLIENT.head("/macro")
      response.body.should be_empty
      response.status.should eq HTTP::Status::OK
    end

    it "works with POST endpoints" do
      CLIENT.post("/macro").body.should eq %("POST")
    end

    it "works with PUT endpoints" do
      CLIENT.put("/macro").body.should eq %("PUT")
    end

    it "works with PATCH endpoints" do
      CLIENT.patch("/macro").body.should eq %("PATCH")
    end

    it "works with DELETE endpoints" do
      CLIENT.delete("/macro").body.should eq %("DELETE")
    end

    it "works with LINK endpoints" do
      CLIENT.exec("LINK", "/macro").body.should eq %("LINK")
    end

    it "works with UNLINK endpoints" do
      CLIENT.exec("UNLINK", "/macro").body.should eq %("UNLINK")
    end

    describe :constraints do
      it "should 404 if it does not match" do
        response = CLIENT.get "/macro/bar"
        response.body.should eq %({"code":404,"message":"No route found for 'GET /macro/bar'"})
        response.status.should eq HTTP::Status::NOT_FOUND
      end

      it "should route correctly if correct" do
        CLIENT.get("/macro/foo").body.should eq %("foo")
      end
    end
  end
end
