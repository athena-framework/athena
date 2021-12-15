require "../spec_helper"

describe ATH::Params::QueryParam do
  describe "#initialize" do
    describe "#nilable?" do
      it "when nilable" do
        ATH::Params::QueryParam(Int32?).new("id", has_default: false, is_nilable: true).nilable?.should be_true
      end

      it "type is Nil" do
        ATH::Params::QueryParam(Nil).new("id", has_default: false, is_nilable: false).nilable?.should be_true
      end

      it "default is nil" do
        ATH::Params::QueryParam(Int32?).new("id", has_default: true, is_nilable: false, default: nil).nilable?.should be_true
      end
    end
  end

  describe "#extract_value" do
    it "missing" do
      request = new_request
      request.query = "bar=1"

      ATH::Params::QueryParam(String).new("name", false, key: "key").extract_value(request, "default").should eq "default"
    end

    it "scalar" do
      request = new_request
      request.query = "key=1"

      ATH::Params::QueryParam(String).new("name", false, key: "key").extract_value(request, "default").should eq "1"
    end

    it "array" do
      request = new_request
      request.query = "key=1&key=2"

      ATH::Params::QueryParam(Array(String)).new("name", false, key: "key").extract_value(request, "default").should eq ["1", "2"]
    end
  end
end
