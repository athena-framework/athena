require "./spec_helper"

describe Athena::Post do
  describe "with an no params" do
    it "works" do
      CLIENT.post("/noParamsPost").body.should eq "foobar"
    end
  end

  describe "with a route param and body param" do
    it "works" do
      CLIENT.post("/double/750", body: "250", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "1000"
    end
  end

  describe "with a route that doesnt exist" do
    it "works" do
      response = CLIENT.post("/dsfdsf")
      response.body.should eq %({"code": 404, "message": "No route found for 'POST /dsfdsf'"})
      response.status_code.should eq 404
    end
  end

  describe "with a route that has a default value" do
    it "works" do
      CLIENT.post("/posts/99", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "100"
      CLIENT.post("/posts/99", body: "100", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "199"
    end
  end

  describe "ParamConverter" do
    describe "RequestBody" do
      context "valid new model" do
        it "should parse an obj from request body" do
          CLIENT.post("/users", body: %({"age":99}), headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq %({"id":12,"age":99})
        end
      end

      context "valid existing model" do
        it "should parse an obj from request body" do
          CLIENT.put("/users", body: %({"id":17,"age":45}), headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq %({"id":17,"age":45})
        end
      end

      context "invalid model" do
        it "should return the validation test failed json object" do
          response = CLIENT.post("/users", body: %({"age":-12}), headers: HTTP::Headers{"content-type" => "application/json"})
          response.body.should eq %({"code":400,"message":"Validation tests failed","errors":["'age' should be greater than 0"]})
          response.status_code.should eq 400
        end
      end

      context "invalid param" do
        it "should return the invalid param json object" do
          response = CLIENT.post("/users", body: %({"age": "foo"}), headers: HTTP::Headers{"content-type" => "application/json"})
          response.body.should eq %({"code": 400, "message": "Expected age to be int but got string"})
          response.status_code.should eq 400

          response = CLIENT.post("/users", body: %({"age": true}), headers: HTTP::Headers{"content-type" => "application/json"})
          response.body.should eq %({"code": 400, "message": "Expected age to be int but got bool"})
          response.status_code.should eq 400

          response = CLIENT.post("/users", body: %({"age": null}), headers: HTTP::Headers{"content-type" => "application/json"})
          response.body.should eq %({"code": 400, "message": "Expected age to be int but got null"})
          response.status_code.should eq 400
        end
      end
    end
  end

  describe "body conversion" do
    context "Int" do
      it "Int8" do
        CLIENT.post("/int8", body: "123", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "123"
      end

      it "Int16" do
        CLIENT.post("/int16/", body: "456", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "456"
      end

      it "Int32" do
        CLIENT.post("/int32/", body: "111111", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "111111"
      end

      it "Int64" do
        CLIENT.post("/int64/", body: "9999999999999999", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "9999999999999999"
      end

      pending "Int128" do
        CLIENT.post("/int128/", body: "9999999999999999999999", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "9999999999999999999999"
      end
    end

    context "UInt" do
      it "UInt8" do
        CLIENT.post("/uint8", body: "123", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "123"
      end

      it "UInt16" do
        CLIENT.post("/uint16", body: "456", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "456"
      end

      it "UInt32" do
        CLIENT.post("/uint32", body: "111111", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "111111"
      end

      it "UInt64" do
        CLIENT.post("/uint64/", body: "9999999999999999", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "9999999999999999"
      end

      pending "UInt128" do
        CLIENT.post("/uint128/", body: "9999999999999999999999", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "9999999999999999999999"
      end
    end

    context "Float" do
      it "Float32" do
        CLIENT.post("/float32/", body: "-2342.223", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "-2342.223"
      end

      it "Float64" do
        CLIENT.post("/float64", body: "2342.234234234223", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "2342.234234234223"
      end
    end

    context "Bool" do
      it "Bool" do
        CLIENT.post("/bool", body: "true", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "true"
      end
    end

    context "String" do
      it "String" do
        CLIENT.post("/string", body: "sdfsd", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "sdfsd"
      end
    end

    context "Struct" do
      it "Struct" do
        CLIENT.post("/struct", body: "123", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "-123"
      end
    end
  end
end
