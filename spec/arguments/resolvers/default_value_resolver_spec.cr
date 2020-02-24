require "../../spec_helper"

describe ART::Arguments::Resolvers::DefaultValue do
  it ".priority" do
    ART::Arguments::Resolvers::DefaultValue.priority.should eq -100
  end

  describe "#supports" do
    it "with a default value" do
      argument = ART::Arguments::ArgumentMetadata(Int32).new("id", true, false)

      ART::Arguments::Resolvers::DefaultValue.new.supports?(new_request, argument).should be_true
    end

    it "nillable not Nil type" do
      argument = ART::Arguments::ArgumentMetadata(Int32?).new("id", false, true)

      ART::Arguments::Resolvers::DefaultValue.new.supports?(new_request, argument).should be_true
    end

    it "Nil type" do
      argument = ART::Arguments::ArgumentMetadata(Nil).new("id", false, true)

      ART::Arguments::Resolvers::DefaultValue.new.supports?(new_request, argument).should be_false
    end

    it "not nillable not Nil type" do
      argument = ART::Arguments::ArgumentMetadata(Int32).new("id", false, false)

      ART::Arguments::Resolvers::DefaultValue.new.supports?(new_request, argument).should be_false
    end
  end

  describe "#resolve" do
    it "with a default value" do
      argument = ART::Arguments::ArgumentMetadata(Int32).new("id", true, false, 100)

      ART::Arguments::Resolvers::DefaultValue.new.resolve(new_request, argument).should eq 100
    end

    it "without a default value" do
      argument = ART::Arguments::ArgumentMetadata(Int32?).new("id", false, true)

      ART::Arguments::Resolvers::DefaultValue.new.resolve(new_request, argument).should be_nil
    end
  end
end
