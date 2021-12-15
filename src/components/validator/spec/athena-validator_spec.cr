require "./spec_helper"

describe Athena::Validator do
  describe ".validator" do
    it "returns a validator" do
      AVD.validator.should be_a AVD::Validator::ValidatorInterface
    end
  end
end
