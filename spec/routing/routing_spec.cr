require "./routing_spec_helper"

do_with_config do |client|
  describe Athena::Routing do
    describe ".run" do
      describe "with custom handlers" do
        describe "when missing the action handler" do
          it "should throw an exception" do
            expect_raises Exception, "Handlers must include 'Athena::Routing::Handlers::ActionHandler'." do
              Athena::Routing.run(handlers: [Athena::Routing::Handlers::CorsHandler.new] of HTTP::Handler)
            end
          end
        end
      end
    end

    describe "with no params" do
      describe "GET" do
        it "works" do
          client.get("/noParamsGet").body.should eq "\"foobar\""
        end
      end

      describe "POST" do
        describe "with only post body" do
          describe "that is optional" do
            it "should return normally" do
              client.post("/noParamsPostOptional").body.should eq "\"foobar\""
            end
          end

          describe "that is required" do
            it "returns correct error" do
              response = client.post("/noParamsPostRequired")
              response.body.should eq %({"code":400,"message":"Request body was not supplied."})
              response.status.should eq HTTP::Status::BAD_REQUEST
            end
          end
        end
      end
    end

    describe "with two params" do
      it "works" do
        client.get("/double/1000/9000").body.should eq "10000"
        client.post("/double/750", body: "250", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "1000"
      end
    end

    describe "that throws a custom exception" do
      it "gets rendered correctly" do
        response = client.get("/get/custom_error")
        response.body.should eq %({"code":418,"message":"teapot"})
        response.status.should eq HTTP::Status::IM_A_TEAPOT
      end
    end

    describe "with a route that doesnt exist" do
      it "returns correct error" do
        response = client.get("/dsfdsf")
        response.body.should eq %({"code":404,"message":"No route found for 'GET /dsfdsf'"})
        response.status.should eq HTTP::Status::NOT_FOUND

        response = client.post("/dsfdsf")
        response.body.should eq %({"code":404,"message":"No route found for 'POST /dsfdsf'"})
        response.status.should eq HTTP::Status::NOT_FOUND
      end
    end

    describe "with a route that has a default value" do
      describe "GET" do
        it "returns the provided value" do
          client.get("/posts/123").body.should eq "123"
        end

        it "returns the default value" do
          client.get("/posts/").body.should eq "99"
        end

        it "does not conflict" do
          client.get("/posts/foo/bvar").body.should eq "\"foo\""
        end
      end

      describe "POST" do
        it "adds using the default value" do
          client.post("/posts/99", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "100"
        end

        it "adds using the provided value" do
          client.post("/posts/99", body: "100", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "199"
        end
      end
    end

    describe "invalid Content-Type" do
      describe "not supported" do
        it "returns correct error" do
          client.post("/posts/99", body: "100", headers: HTTP::Headers{"content-type" => "application/foo"}).body.should eq %({"code":415,"message":"Invalid Content-Type: 'application/foo'"})
        end
      end

      describe "missing" do
        it "should default to text/plain" do
          client.post("/posts/99", body: "100").body.should eq "199"
        end
      end
    end

    describe "nil return type" do
      it "should return 204 no content" do
        response = client.get("/get/nil_return")
        response.status.should eq HTTP::Status::NO_CONTENT
        response.body.should be_empty
      end

      describe "and the response status was changed in the action" do
        it "should not use no content" do
          response = client.get("/get/nil_return/updated_status")
          response.status.should eq HTTP::Status::IM_A_TEAPOT
          response.body.should be_empty
        end
      end
    end

    describe "#get_request" do
      it "has access to the request object" do
        client.get("/get/request").body.should eq "\"/get/request\""
      end
    end

    describe "#get_response" do
      it "has access to the response object" do
        client.get("/get/response").headers.includes_word?("Foo", "Bar").should be_true
      end
    end

    it "is concurrently safe" do
      spawn do
        sleep 1
        HTTP::Client.get("http://localhost:8888/get/safe?bar").body.should eq %("safe")
      end
      client.get("/get/safe?foo").body.should eq "\"safe\""
    end
  end
end
