require "../../spec_helper"

describe ATH::Arguments::Resolvers::DefaultValue do
  describe "#supports" do
    it "with a default value" do
      argument = ATH::Arguments::ArgumentMetadata(Int32).new("id", true, false)

      ATH::Arguments::Resolvers::DefaultValue.new.supports?(new_request, argument).should be_true
    end

    it "nilable not Nil type" do
      argument = ATH::Arguments::ArgumentMetadata(Int32?).new("id", false, true)

      ATH::Arguments::Resolvers::DefaultValue.new.supports?(new_request, argument).should be_true
    end

    it "Nil type" do
      argument = ATH::Arguments::ArgumentMetadata(Nil).new("id", false, true)

      ATH::Arguments::Resolvers::DefaultValue.new.supports?(new_request, argument).should be_false
    end

    it "not nilable not Nil type" do
      argument = ATH::Arguments::ArgumentMetadata(Int32).new("id", false, false)

      ATH::Arguments::Resolvers::DefaultValue.new.supports?(new_request, argument).should be_false
    end
  end

  describe "#resolve" do
    it "with a default value" do
      argument = ATH::Arguments::ArgumentMetadata(Int32).new("id", true, false, 100)

      ATH::Arguments::Resolvers::DefaultValue.new.resolve(new_request, argument).should eq 100
    end

    it "without a default value" do
      argument = ATH::Arguments::ArgumentMetadata(Int32?).new("id", false, true)

      ATH::Arguments::Resolvers::DefaultValue.new.resolve(new_request, argument).should be_nil
    end
  end
end
