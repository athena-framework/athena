require "./spec_helper"

describe Athena::Get do
  describe "with an no params" do
    it "works" do
      CLIENT.get("/noParamsGet").body.should eq "foobar"
    end
  end

  describe "with two route params" do
    it "works" do
      CLIENT.get("/double/1000/9000").body.should eq "10000"
    end
  end

  describe "with a route that doesnt exist" do
    it "works" do
      response = CLIENT.get("/dsfdsf")
      response.body.should eq %({"code": 404, "message": "No route found for 'GET /dsfdsf'"})
      response.status_code.should eq 404
    end
  end

  describe "with a route that has a default value" do
    it "works" do
      CLIENT.get("/posts/123").body.should eq "123"
      CLIENT.get("/posts/").body.should eq "99"
      CLIENT.get("/posts/foo/bvar").body.should eq "foo"
    end
  end

  describe "ParamConverter" do
    describe "with an Exists param converter" do
      it "resolves a record that exists" do
        CLIENT.get("/users/17").body.should eq %({"id":17,"age":123})
      end

      it "returns correct error if the record does not exist" do
        response = CLIENT.get("/users/34")
        response.body.should eq %({"code":404,"message":"An item with the provided ID could not be found."})
        response.status_code.should eq 404
      end
    end
  end

  describe "callbacks" do
    describe "user endpoint" do
      it "should set the correct headers" do
        headers = CLIENT.get("/callback/users").headers
        headers.includes_word?("X-RESPONSE-ALL-ROUTES", "true").should be_true
        headers.includes_word?("X-RESPONSE-USER-ROUTE", "true").should be_true
        headers.includes_word?("X-REQUEST-NOT-POSTS-ROUTE", "true").should be_true
      end
    end

    describe "all endpoint" do
      it "should set the correct headers" do
        headers = CLIENT.get("/callback/all").headers
        headers.includes_word?("X-RESPONSE-ALL-ROUTES", "true").should be_true
        headers.includes_word?("X-RESPONSE-USER-ROUTE", "true").should be_false
        headers.includes_word?("X-REQUEST-NOT-POSTS-ROUTE", "true").should be_true
      end
    end

    describe "posts endpoint" do
      it "should set the correct headers" do
        headers = CLIENT.get("/callback/posts").headers
        headers.includes_word?("X-RESPONSE-ALL-ROUTES", "true").should be_true
        headers.includes_word?("X-RESPONSE-USER-ROUTE", "true").should be_false
        headers.includes_word?("X-REQUEST-NOT-POSTS-ROUTE", "true").should be_false
      end
    end

    describe "in another controller" do
      it "should not set the headers" do
        headers = CLIENT.get("/callback/other").headers
        headers.includes_word?("X-RESPONSE-ALL-ROUTES", "true").should be_false
        headers.includes_word?("X-RESPONSE-USER-ROUTE", "true").should be_false
        headers.includes_word?("X-REQUEST-NOT-POSTS-ROUTE", "true").should be_false
      end
    end
  end

  describe "param conversion" do
    context "Int" do
      it "Int8" do
        CLIENT.get("/int8/123").body.should eq "123"
      end

      it "Int16" do
        CLIENT.get("/int16/456").body.should eq "456"
      end

      it "Int32" do
        CLIENT.get("/int32/111111").body.should eq "111111"
      end

      it "Int64" do
        CLIENT.get("/int64/9999999999999999").body.should eq "9999999999999999"
      end

      pending "Int128" do
        CLIENT.get("/int128/9999999999999999999999").body.should eq "9999999999999999999999"
      end
    end

    context "UInt" do
      it "UInt8" do
        CLIENT.get("/uint8/123").body.should eq "123"
      end

      it "UInt16" do
        CLIENT.get("/uint16/456").body.should eq "456"
      end

      it "UInt32" do
        CLIENT.get("/uint32/111111").body.should eq "111111"
      end

      it "UInt64" do
        CLIENT.get("/uint64/9999999999999999").body.should eq "9999999999999999"
      end

      pending "UInt128" do
        CLIENT.get("/uint128/9999999999999999999999").body.should eq "9999999999999999999999"
      end
    end

    context "Float" do
      it "Float32" do
        CLIENT.get("/float32/-2342.223").body.should eq "-2342.223"
      end

      it "Float64" do
        CLIENT.get("/float64/2342.234234234223").body.should eq "2342.234234234223"
      end
    end

    context "Bool" do
      it "Bool" do
        CLIENT.get("/bool/true").body.should eq "true"
      end
    end

    context "String" do
      it "String" do
        CLIENT.get("/string/sdfsd").body.should eq "sdfsd"
      end
    end

    context "Struct" do
      it "Struct" do
        CLIENT.get("/struct/123").body.should eq "-123"
      end
    end
  end
end
