require "../../spec_helper"

describe ATH::Arguments::Resolvers::DefaultValue do
  describe "#resolve" do
    it "does not have a default nor is nilable" do
      argument = ATH::Arguments::ArgumentMetadata(String).new "foo", false, nil

      ATH::Arguments::Resolvers::DefaultValue.new.resolve(new_request, argument).should be_nil
    end

    it "does not have a default but is nilable" do
      argument = ATH::Arguments::ArgumentMetadata(String?).new "foo", false, nil

      ATH::Arguments::Resolvers::DefaultValue.new.resolve(new_request, argument).should be_nil
    end

    it "has a nil default value and is nilable" do
      argument = ATH::Arguments::ArgumentMetadata(String?).new "foo", true, nil

      ATH::Arguments::Resolvers::DefaultValue.new.resolve(new_request, argument).should be_nil
    end

    it "with a default value" do
      argument = ATH::Arguments::ArgumentMetadata(String).new "foo", true, "bar"

      ATH::Arguments::Resolvers::DefaultValue.new.resolve(new_request, argument).should eq "bar"
    end
  end
end
