require "./spec_helper"

describe ART::ArgumentResolver do
  run_server

  describe "with a request parameter" do
    it "should return the current request's path" do
      CLIENT.get("/request").body.should eq %("/request")
    end
  end

  describe :required do
    describe nil do
      it "should return a 400 if no default is given" do
        response = CLIENT.get("/not-nil-missing")
        response.status.should eq HTTP::Status::BAD_REQUEST
        response.body.should eq %({"code":400,"message":"Missing required query parameter 'id'"})
      end

      it "should use the default if a default is given" do
        response = CLIENT.get("/not-nil-default")
        response.body.should eq "24"
      end
    end

    it "should return the value if it was able to be converted" do
      CLIENT.get("/not-nil/19").body.should eq "19"
    end

    it "should raise a 422 if the value could not be converted" do
      response = CLIENT.get("/not-nil/foo")
      response.status.should eq HTTP::Status::UNPROCESSABLE_ENTITY
      response.body.should eq %({"code":422,"message":"Required parameter 'id' with value 'foo' could not be converted into a valid 'Int32'"})
    end
  end

  describe :optional do
    describe :not_provided do
      it "should return null if no default is given" do
        response = CLIENT.get("/nil")
        response.body.should eq "null"
      end

      it "should use the default if a default is given" do
        response = CLIENT.get("/nil-default")
        response.body.should eq "19"
      end
    end

    describe :provided do
      it "should return the value if provided" do
        CLIENT.get("/nil?id=19").body.should eq "19"
      end

      it "should return nil if not provided" do
        CLIENT.get("/nil?id=foo").body.should eq "null"
      end
    end
  end

  describe "query param with a constraint" do
    it "should return the value if it matches" do
      CLIENT.get("/event?time=1:2:3").body.should eq %("1:2:3")
    end

    it "should raise a 422 if the value does not match" do
      response = CLIENT.get("/event?time=1:a:3")
      response.status.should eq HTTP::Status::UNPROCESSABLE_ENTITY
      response.body.should eq %({"code":422,"message":"Expected query parameter 'time' to match '(?-imsx:\\\\d:\\\\d:\\\\d)' but got '1:a:3'"})
    end
  end
end
