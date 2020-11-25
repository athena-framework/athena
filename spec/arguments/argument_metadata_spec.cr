require "../spec_helper"

describe ART::Arguments::ArgumentMetadata do
  describe "#initialize" do
    describe "#nilable?" do
      it "when is_nilable is true" do
        ART::Arguments::ArgumentMetadata(Int32).new("id", false, true).nilable?.should be_true
      end

      it "type is Nil" do
        ART::Arguments::ArgumentMetadata(Nil).new("id", false, false).nilable?.should be_true
      end

      it "default is nil" do
        ART::Arguments::ArgumentMetadata(Int32?).new("id", true, false, nil).nilable?.should be_true
      end
    end
  end
end
