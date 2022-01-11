require "../spec_helper"

describe ATH::Arguments::ArgumentMetadata do
  describe "#initialize" do
    describe "#nilable?" do
      it "when is_nilable is true" do
        ATH::Arguments::ArgumentMetadata(Int32).new("id", true).nilable?.should be_true
      end

      it "type is Nil" do
        ATH::Arguments::ArgumentMetadata(Nil).new("id", false).nilable?.should be_true
      end
    end
  end
end
