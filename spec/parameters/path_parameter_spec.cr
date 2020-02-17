require "../spec_helper"

describe ART::Parameters::Path do
  describe "#extract" do
    describe :missing do
      it "should return nil" do
        ART::Parameters::Path(Int32).new("id").extract(new_request).should be_nil
      end
    end

    describe :provided do
      it "should return the value" do
        ART::Parameters::Path(Int32).new("id").extract(new_request(path_params: {"id" => "123"})).should eq "123"
      end
    end
  end

  describe "#parameter_type" do
    it "should return the proper type" do
      ART::Parameters::Path(Int32).new("id").parameter_type.should eq "path"
    end
  end
end
