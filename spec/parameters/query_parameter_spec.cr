require "../spec_helper"

describe ART::Parameters::Query do
  describe "#extract" do
    describe :missing do
      it "should return nil" do
        ART::Parameters::Query(Int32).new("id").extract(new_request).should be_nil
      end
    end

    describe :provided do
      it "should return the value" do
        request = new_request
        request.query = "id=123"

        ART::Parameters::Query(Int32).new("id").extract(request).should eq "123"
      end
    end

    describe :pattern do
      describe "that matches" do
        it "should return the value" do
          request = new_request
          request.query = "id=123"

          ART::Parameters::Query(Int32).new("id", pattern: /\d{3}/).extract(request).should eq "123"
        end
      end

      describe "that does not match" do
        it "should raise a 422" do
          request = new_request
          request.query = "id=12"

          expect_raises ART::Exceptions::UnprocessableEntity, "Expected query parameter 'id' to match '(?-imsx:\\d{3})' but got '12'" do
            ART::Parameters::Query(Int32).new("id", pattern: /\d{3}/).extract request
          end
        end
      end

      describe "that does not match but the value is nil" do
        it "should return nil" do
          ART::Parameters::Query(Int32).new("id", pattern: /\d{3}/).extract(new_request).should be_nil
        end
      end
    end
  end

  describe "#parameter_type" do
    it "should return the proper type" do
      ART::Parameters::Query(Int32).new("id").parameter_type.should eq "query"
    end
  end
end
