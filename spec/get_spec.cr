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
    it "returns correct error" do
      response = CLIENT.get("/dsfdsf")
      response.body.should eq %({"code": 404, "message": "No route found for 'GET /dsfdsf'"})
      response.status_code.should eq 404
    end
  end

  describe "route constraints" do
    context "that is valid" do
      it "works" do
        CLIENT.get("/get/constraints/4:5:6").body.should eq "4:5:6"
      end
    end

    context "that is invalid" do
      it "returns correct error" do
        response = CLIENT.get("/get/constraints/4:a:6")
        response.body.should eq %({"code": 404, "message": "No route found for 'GET /get/constraints/4:a:6'"})
        response.status_code.should eq 404
      end
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

  describe "renderers" do
    describe "yaml" do
      it "should render correctly" do
        CLIENT.get("/users/yaml/17").body.should eq %(---\nid: 17\nage: 123\npassword: monkey\n)
      end
    end

    describe "ecr" do
      it "should render correctly" do
        CLIENT.get("/users/ecr/17").body.should eq %(User 17 is 123 years old.)
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
        headers.includes_word?("X-RESPONSE-GLOBAL", "true").should be_true
      end
    end

    describe "all endpoint" do
      it "should set the correct headers" do
        headers = CLIENT.get("/callback/all").headers
        headers.includes_word?("X-RESPONSE-ALL-ROUTES", "true").should be_true
        headers.includes_word?("X-RESPONSE-USER-ROUTE", "true").should be_false
        headers.includes_word?("X-REQUEST-NOT-POSTS-ROUTE", "true").should be_true
        headers.includes_word?("X-RESPONSE-GLOBAL", "true").should be_true
      end
    end

    describe "posts endpoint" do
      it "should set the correct headers" do
        headers = CLIENT.get("/callback/posts").headers
        headers.includes_word?("X-RESPONSE-ALL-ROUTES", "true").should be_true
        headers.includes_word?("X-RESPONSE-USER-ROUTE", "true").should be_false
        headers.includes_word?("X-REQUEST-NOT-POSTS-ROUTE", "true").should be_false
        headers.includes_word?("X-RESPONSE-GLOBAL", "true").should be_false
      end
    end

    describe "in another controller" do
      headers = CLIENT.get("/callback/other").headers

      it "should not set the `CallbackController`'s' headers" do
        headers.includes_word?("X-RESPONSE-ALL-ROUTES", "true").should be_false
        headers.includes_word?("X-RESPONSE-USER-ROUTE", "true").should be_false
        headers.includes_word?("X-REQUEST-NOT-POSTS-ROUTE", "true").should be_false
        headers.includes_word?("X-RESPONSE-GLOBAL", "true").should be_true
      end

      it "should set the global callback header" do
        headers.includes_word?("X-RESPONSE-GLOBAL", "true").should be_true
      end
    end
  end

  describe "with a view" do
    describe "default group" do
      it "should serialize correctly" do
        CLIENT.get("/users/17").body.should eq %({"id":17,"age":123})
      end
    end

    describe "admin group" do
      it "should serialize correctly" do
        CLIENT.get("/admin/users/17").body.should eq %({"password":"monkey"})
      end
    end

    describe "admin + default" do
      it "should serialize correctly" do
        CLIENT.get("/admin/users/17/all").body.should eq %({"id":17,"age":123,"password":"monkey"})
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
