require "../../spec_helper"

enum TestEnum
  A
  B
  C
end

describe ATH::Arguments::Resolvers::Enum do
  describe "#supports?" do
    describe ::Enum do
      describe "exists in request attributes" do
        it "is not a string" do
          argument = ATH::Arguments::ArgumentMetadata(TestEnum).new "enum"
          request = new_request
          request.attributes.set "enum", 1

          ATH::Arguments::Resolvers::Enum.new.supports?(request, argument).should be_false
        end

        it "the enum member is nilable" do
          argument = ATH::Arguments::ArgumentMetadata(TestEnum?).new "enum"
          request = new_request
          request.attributes.set "enum", "1"

          ATH::Arguments::Resolvers::Enum.new.supports?(request, argument).should be_true
        end

        it "that is a union of another type" do
          argument = ATH::Arguments::ArgumentMetadata(TestEnum | String).new "enum"
          request = new_request
          request.attributes.set "enum", "1"

          ATH::Arguments::Resolvers::Enum.new.supports?(request, argument).should be_true
        end
      end

      it "that does not exist in request attributes" do
        argument = ATH::Arguments::ArgumentMetadata(TestEnum).new "enum"

        ATH::Arguments::Resolvers::Enum.new.supports?(new_request, argument).should be_false
      end

      it "that is nilable and not exist in request attributes" do
        argument = ATH::Arguments::ArgumentMetadata(TestEnum?).new "enum"

        ATH::Arguments::Resolvers::Enum.new.supports?(new_request, argument).should be_false
      end
    end

    it "some other type" do
      ATH::Arguments::Resolvers::Enum.new.supports?(new_request, ATH::Arguments::ArgumentMetadata(Int32).new "enum").should be_false
      ATH::Arguments::Resolvers::Enum.new.supports?(new_request, ATH::Arguments::ArgumentMetadata(Int32?).new "enum").should be_false
      ATH::Arguments::Resolvers::Enum.new.supports?(new_request, ATH::Arguments::ArgumentMetadata(Bool | String).new "enum").should be_false
    end
  end

  describe "#resolve" do
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
