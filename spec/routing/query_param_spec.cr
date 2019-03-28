require "./routing_spec_helper"

describe "QueryParams" do
  describe "when it is required" do
    context "with a constraint" do
      describe "that is not provided " do
        it "should raise proper error" do
          response = CLIENT.get("/get/query_param_constraint_required")
          response.body.should eq %({"code":400,"message":"Required query param 'time' was not supplied."})
          response.status_code.should eq 400
        end
      end

      describe "that is supplied" do
        it "should return the value" do
          CLIENT.get("/get/query_param_constraint_required?time=1:2:3").body.should eq "\"1:2:3\""
        end
      end

      describe "that is supplied but doesn't match" do
        it "should raise proper error" do
          response = CLIENT.get("/get/query_param_constraint_required?time=1:a:3")
          response.body.should eq %q({"code":400,"message":"Expected query param 'time' to match '(?-imsx:\\d:\\d:\\d)' but got '1:a:3'"})
          response.status_code.should eq 400
        end
      end
    end

    context "without a constraint" do
      describe "that is not provided " do
        it "should raise proper error" do
          response = CLIENT.get("/get/query_param_required")
          response.body.should eq %({"code":400,"message":"Required query param 'time' was not supplied."})
          response.status_code.should eq 400
        end
      end

      describe "that is supplied" do
        it "should return the value" do
          CLIENT.get("/get/query_param_required?time=1:2:3").body.should eq "\"1:2:3\""
        end
      end
    end
  end

  describe "when it is optional" do
    context "with a constraint" do
      describe "that is not provided " do
        it "should return nil" do
          CLIENT.get("/get/query_params_constraint_optional").body.should eq "null"
        end
      end

      describe "that is supplied" do
        it "should return the value" do
          CLIENT.get("/get/query_params_constraint_optional?time=1:2:3").body.should eq "\"1:2:3\""
        end
      end

      describe "that is supplied but doesn't match" do
        it "should return nil" do
          CLIENT.get("/get/query_params_constraint_optional").body.should eq "null"
        end
      end

      describe "that is not supplied but has a default value" do
        it "should return the default value" do
          CLIENT.get("/get/query_params_constraint_optional_default").body.should eq "\"foo\""
        end
      end
    end

    context "without a constraint" do
      describe "that is not provided " do
        it "should return nil" do
          CLIENT.get("/get/query_params_optional").body.should eq "null"
        end
      end

      describe "that is supplied" do
        it "should return the value" do
          CLIENT.get("/get/query_params_optional?time=1:2:3").body.should eq "\"1:2:3\""
        end
      end
    end

    context "with a default value" do
      describe "that is not provided " do
        it "should return the default value" do
          CLIENT.get("/get/query_params_optional_default").body.should eq "999"
        end
      end

      describe "that is supplied" do
        it "should return the value" do
          CLIENT.get("/get/query_params_optional_default?page=13").body.should eq "13"
        end
      end
    end
  end
end
