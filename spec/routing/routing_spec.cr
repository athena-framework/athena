require "./routing_spec_helper"

do_with_config do
  describe Athena::Routing do
    describe "with no params" do
      describe "GET" do
        it "works" do
          CLIENT.get("/noParamsGet").body.should eq "\"foobar\""
        end
      end

      describe "POST" do
        describe "with only post body" do
          describe "that is optional" do
            it "should return normally" do
              CLIENT.post("/noParamsPostOptional").body.should eq "\"foobar\""
            end
          end

          describe "that is required" do
            it "returns correct error" do
              response = CLIENT.post("/noParamsPostRequired")
              response.body.should eq %({"code":400,"message":"Request body was not supplied."})
              response.status_code.should eq 400
            end
          end
        end
      end
    end

    describe "with two params" do
      it "works" do
        CLIENT.get("/double/1000/9000").body.should eq "10000"
        CLIENT.post("/double/750", body: "250", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "1000"
      end
    end

    describe "with a prefix" do
      it "should route correctly" do
        CLIENT.get("/calendar/events").body.should eq "\"events\""
        CLIENT.get("/calendar/external").body.should eq "\"calendars\""
      end
    end

    describe "that throws a custom exception" do
      it "gets rendered correctly" do
        response = CLIENT.get("/get/custom_error")
        response.body.should eq %({"code":418,"message":"teapot"})
        response.status_code.should eq 418
      end
    end

    describe "with a route that doesnt exist" do
      it "returns correct error" do
        response = CLIENT.get("/dsfdsf")
        response.body.should eq %({"code":404,"message":"No route found for 'GET /dsfdsf'"})
        response.status_code.should eq 404

        response = CLIENT.post("/dsfdsf")
        response.body.should eq %({"code":404,"message":"No route found for 'POST /dsfdsf'"})
        response.status_code.should eq 404
      end
    end

    describe "with a route that has a default value" do
      context "GET" do
        it "returns the provided value" do
          CLIENT.get("/posts/123").body.should eq "123"
        end

        it "returns the default value" do
          CLIENT.get("/posts/").body.should eq "99"
        end

        it "does not conflict" do
          CLIENT.get("/posts/foo/bvar").body.should eq "\"foo\""
        end
      end

      context "POST" do
        it "adds using the default value" do
          CLIENT.post("/posts/99", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "100"
        end

        it "adds using the provided value" do
          CLIENT.post("/posts/99", body: "100", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "199"
        end
      end
    end

    describe "invalid Content-Type" do
      context "not supported" do
        it "returns correct error" do
          CLIENT.post("/posts/99", body: "100", headers: HTTP::Headers{"content-type" => "application/foo"}).body.should eq %({"code":415,"message":"Invalid Content-Type: 'application/foo'"})
        end
      end

      context "missing" do
        it "should default to text/plain" do
          CLIENT.post("/posts/99", body: "100").body.should eq "199"
        end
      end
    end

    describe "for a struct" do
      describe ".get_response" do
        it "has access to the response object" do
          CLIENT.get("/get/struct/response").headers.includes_word?("Foo", "Bar").should be_true
        end
      end

      describe ".get_request" do
        it "has access to the request object" do
          CLIENT.get("/get/struct/request").body.should eq "\"/get/struct/request\""
        end
      end
    end

    describe "for a class" do
      describe ".get_response" do
        it "has access to the response object" do
          CLIENT.get("/get/class/response").headers.includes_word?("Foo", "Bar").should be_true
        end
      end

      describe ".get_request" do
        it "has access to the request object" do
          CLIENT.get("/get/class/request").body.should eq "\"/get/class/request\""
        end
      end
    end
  end
end
