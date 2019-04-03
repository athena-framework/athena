require "./routing_spec_helper"

do_with_config do |client|
  describe Athena::Routing::ParamConverter do
    describe "Exists" do
      it "resolves a record that exists" do
        client.get("/users/17").body.should eq %({"id":17,"age":123})
      end

      it "resolves a record that exists with a String PK" do
        client.get("/users/str/71").body.should eq %({"id":71,"age":321})
      end

      it "returns correct error if the record does not exist" do
        response = client.get("/users/34")
        response.body.should eq %({"code":404,"message":"An item with the provided ID could not be found."})
        response.status_code.should eq 404
      end

      it "resolves a record that has the characters '_id' in it" do
        client.get("/article/17").body.should eq %({"id":17,"title":"Int"})
      end
    end

    describe "RequestBody" do
      context "valid new model" do
        it "should parse an obj from request body" do
          client.post("/users", body: %({"age":99}), headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq %({"id":12,"age":99})
        end
      end

      context "valid existing model" do
        it "should parse an obj from request body" do
          client.put("/users", body: %({"id":17,"age":99}), headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq %({"id":17,"age":99})
        end
      end

      context "invalid model" do
        it "should return the validation test failed json object" do
          response = client.post("/users", body: %({"age":-12}), headers: HTTP::Headers{"content-type" => "application/json"})
          response.body.should eq %({"code":400,"message":"Validation tests failed","errors":["'age' should be greater than 0"]})
          response.status_code.should eq 400
        end
      end

      context "invalid param" do
        it "should return the invalid param json object" do
          response = client.post("/users", body: %({"age": "foo"}), headers: HTTP::Headers{"content-type" => "application/json"})
          response.body.should eq %({"code": 400, "message": "Expected 'age' to be int but got string"})
          response.status_code.should eq 400

          response = client.post("/users", body: %({"age": true}), headers: HTTP::Headers{"content-type" => "application/json"})
          response.body.should eq %({"code": 400, "message": "Expected 'age' to be int but got bool"})
          response.status_code.should eq 400

          response = client.post("/users", body: %({"age": null}), headers: HTTP::Headers{"content-type" => "application/json"})
          response.body.should eq %({"code": 400, "message": "Expected 'age' to be int but got null"})
          response.status_code.should eq 400
        end
      end
    end

    describe "FormData" do
      context "valid new model" do
        it "should parse an obj from request body" do
          client.post("/users/form", body: %(age=1&id=99), headers: HTTP::Headers{"content-type" => "application/x-www-form-urlencoded"}).body.should eq %({"id":99,"age":1})
        end
      end
    end
  end
end
