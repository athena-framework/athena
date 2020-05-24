require "../spec_helper"

describe ART::Arguments::ArgumentMetadata do
  describe "#initialize" do
    describe "#nillable?" do
      it "when is_nillable is true" do
        ART::Arguments::ArgumentMetadata(Int32).new("id", false, true).nillable?.should be_true
      end

      it "type is Nil" do
        ART::Arguments::ArgumentMetadata(Nil).new("id", false, false).nillable?.should be_true
      end

      it "default is nil" do
        ART::Arguments::ArgumentMetadata(Int32?).new("id", true, false, nil).nillable?.should be_true
      end
    end
  end
end
