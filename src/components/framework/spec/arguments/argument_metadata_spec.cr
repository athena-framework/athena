require "../spec_helper"

describe ATH::Arguments::ArgumentMetadata do
  describe "#initialize" do
    describe "#nilable?" do
      it "when is_nilable is true" do
        ATH::Arguments::ArgumentMetadata(Int32).new("id").nilable?.should be_false
        ATH::Arguments::ArgumentMetadata(String | Bool).new("id").nilable?.should be_false
      end

      it "type is Nil" do
        ATH::Arguments::ArgumentMetadata(Nil).new("id").nilable?.should be_true
        ATH::Arguments::ArgumentMetadata(Int32?).new("id").nilable?.should be_true
        ATH::Arguments::ArgumentMetadata(String | Bool | Nil).new("id").nilable?.should be_true
      end
    end
  end
end
