require "../../spec_helper"

describe ATH::Arguments::Resolvers::DefaultValue do
  describe "#supports?" do
    it "does not have a default nor is nilable" do
      argument = ATH::Arguments::ArgumentMetadata(String).new "foo", false, nil

      ATH::Arguments::Resolvers::DefaultValue.new.supports?(new_request, argument).should be_false
    end

    it "has a non-nilable default" do
      argument = ATH::Arguments::ArgumentMetadata(String).new "foo", true, "bar"

      ATH::Arguments::Resolvers::DefaultValue.new.supports?(new_request, argument).should be_true
    end

    it "does not have a default but is nilable" do
      argument = ATH::Arguments::ArgumentMetadata(String?).new "foo", false, nil

      ATH::Arguments::Resolvers::DefaultValue.new.supports?(new_request, argument).should be_true
    end

    it "has a nil default value and is nilable" do
      argument = ATH::Arguments::ArgumentMetadata(String?).new "foo", true, nil

      ATH::Arguments::Resolvers::DefaultValue.new.supports?(new_request, argument).should be_true
    end
  end

  describe "#resolve" do
    it "with a default value" do
      argument = ATH::Arguments::ArgumentMetadata(String).new "foo", true, "bar"

      ATH::Arguments::Resolvers::DefaultValue.new.resolve(new_request, argument).should eq "bar"
    end

    it "with a nilable value" do
      argument = ATH::Arguments::ArgumentMetadata(String?).new "foo", false, nil

      ATH::Arguments::Resolvers::DefaultValue.new.resolve(new_request, argument).should be_nil
    end
  end
end
