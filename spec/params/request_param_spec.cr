require "../spec_helper"

describe ART::Params::RequestParam do
  describe "#initialize" do
    describe "#nilable?" do
      it "when is_nilable is true" do
        ART::Params::RequestParam(Int32).new("id", has_default: false, is_nilable: true).nilable?.should be_true
      end

      it "type is Nil" do
        ART::Params::RequestParam(Nil).new("id", has_default: false, is_nilable: false).nilable?.should be_true
      end

      it "default is nil" do
        ART::Params::RequestParam(Int32?).new("id", has_default: true, is_nilable: false, default: nil).nilable?.should be_true
      end
    end
  end

  describe "#parse_value" do
    it "missing" do
      request = new_request
      request.body = "bar=1"

      ART::Params::RequestParam(String).new("name", false, key: "key").parse_value(request, "default").should eq "default"
    end

    it "scalar" do
      request = new_request
      request.body = "key=1"

      ART::Params::RequestParam(String).new("name", false, key: "key").parse_value(request, "default").should eq "1"
    end

    it "array" do
      request = new_request
      request.body = "key=1&key=2"

      ART::Params::RequestParam(Array(String)).new("name", false, key: "key").parse_value(request, "default").should eq ["1", "2"]
    end
  end
end
