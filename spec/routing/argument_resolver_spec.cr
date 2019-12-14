require "./routing_spec_helper"

describe ART::ArgumentResolver do
  run_server

  describe "with a request paramter" do
    it "should return the current request's path" do
      CLIENT.get("/request").body.should eq %("/request")
    end
  end

  describe :required do
    describe nil do
      describe "no default" do
        it "should return a 400" do
          response = CLIENT.get("/not-nil-missing")
          response.status.should eq HTTP::Status::BAD_REQUEST
          response.body.should eq %({"code":400,"message":"Missing required query parameter 'id'"})
        end
      end

      describe "with default" do
        it "should use the default" do
          response = CLIENT.get("/not-nil-default")
          response.body.should eq "19"
        end
      end
    end

    describe "valid" do
      it "should return the converted value" do
        CLIENT.get("/not-nil/19").body.should eq "19"
      end
    end

    describe "invalid" do
      it "should return a 422" do
        response = CLIENT.get("/not-nil/foo")
        response.status.should eq HTTP::Status::UNPROCESSABLE_ENTITY
        response.body.should eq %({"code":422,"message":"Required parameter 'id' with value 'foo' could not be converted into a valid 'Int32'"})
      end
    end
  end

  describe :optional do
    describe :not_provided do
      describe "no default" do
        it "should return null" do
          response = CLIENT.get("/nil")
          response.body.should eq "null"
        end
      end

      describe "with default" do
        it "should use the default" do
          response = CLIENT.get("/nil-default")
          response.body.should eq "19"
        end
      end
    end

    describe :provided do
      describe "valid" do
        it "should return the value" do
          CLIENT.get("/nil?id=19").body.should eq "19"
        end
      end

      describe "invalid" do
        it "should return nil" do
          CLIENT.get("/nil?id=foo").body.should eq "null"
        end
      end
    end
  end

  describe :converter do
    it "should return the converted value" do
      CLIENT.get("/double/2").body.should eq "4"
    end
  end
end
