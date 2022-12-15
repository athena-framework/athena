require "../../spec_helper"

enum TestEnum
  A
  B
  C
end

describe ATH::Arguments::Resolvers::Enum do
  describe "#resolve" do
    it "some other type" do
      ATH::Arguments::Resolvers::Enum.new.resolve(new_request, ATH::Arguments::ArgumentMetadata(Int32).new "enum").should be_nil
      ATH::Arguments::Resolvers::Enum.new.resolve(new_request, ATH::Arguments::ArgumentMetadata(Int32?).new "enum").should be_nil
      ATH::Arguments::Resolvers::Enum.new.resolve(new_request, ATH::Arguments::ArgumentMetadata(Bool | String).new "enum").should be_nil
    end

    it "is not a string" do
      argument = ATH::Arguments::ArgumentMetadata(TestEnum).new "enum"
      request = new_request
      request.attributes.set "enum", 1

      ATH::Arguments::Resolvers::Enum.new.resolve(request, argument).should be_nil
    end

    it "that does not exist in request attributes" do
      argument = ATH::Arguments::ArgumentMetadata(TestEnum).new "enum"

      ATH::Arguments::Resolvers::Enum.new.resolve(new_request, argument).should be_nil
    end

    it "that is nilable and not exist in request attributes" do
      argument = ATH::Arguments::ArgumentMetadata(TestEnum?).new "enum"

      ATH::Arguments::Resolvers::Enum.new.resolve(new_request, argument).should be_nil
    end

    it "that is a union of another type" do
      argument = ATH::Arguments::ArgumentMetadata(TestEnum | String).new "enum"
      request = new_request
      request.attributes.set "enum", "1"

      ATH::Arguments::Resolvers::Enum.new.resolve(request, argument).should eq TestEnum::B
    end

    it "the enum member is nilable" do
      argument = ATH::Arguments::ArgumentMetadata(TestEnum?).new "enum"
      request = new_request
      request.attributes.set "enum", "1"

      ATH::Arguments::Resolvers::Enum.new.resolve(request, argument).should eq TestEnum::B
    end

    it "with a numeric based value" do
      argument = ATH::Arguments::ArgumentMetadata(TestEnum).new "enum"

      request = new_request
      request.attributes.set "enum", "2"

      ATH::Arguments::Resolvers::Enum.new.resolve(request, argument).should eq TestEnum::C
    end

    it "with a numeric based value with whitespace" do
      argument = ATH::Arguments::ArgumentMetadata(TestEnum).new "enum"

      request = new_request
      request.attributes.set "enum", "2"

      ATH::Arguments::Resolvers::Enum.new.resolve(request, argument).should eq TestEnum::C
    end

    it "with a string based value" do
      argument = ATH::Arguments::ArgumentMetadata(TestEnum).new "enum"

      request = new_request
      request.attributes.set "enum", "B"

      ATH::Arguments::Resolvers::Enum.new.resolve(request, argument).should eq TestEnum::B
    end

    it "with a string based nilable value" do
      argument = ATH::Arguments::ArgumentMetadata(TestEnum?).new "enum"

      request = new_request
      request.attributes.set "enum", "B"

      ATH::Arguments::Resolvers::Enum.new.resolve(request, argument).should eq TestEnum::B
    end

    it "with an unknown member value" do
      argument = ATH::Arguments::ArgumentMetadata(TestEnum).new "enum"

      request = new_request
      request.attributes.set "enum", "  4  "

      expect_raises ATH::Exceptions::BadRequest, "Parameter 'enum' of enum type 'TestEnum' has no valid member for '  4  '." do
        ATH::Arguments::Resolvers::Enum.new.resolve request, argument
      end
    end
  end
end
