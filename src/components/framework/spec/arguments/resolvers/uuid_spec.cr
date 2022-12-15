require "../../spec_helper"

describe ATH::Arguments::Resolvers::UUID do
  describe "#resolve" do
    it "does not exist in request attributes" do
      argument = ATH::Arguments::ArgumentMetadata(UUID).new "foo"
      ATH::Arguments::Resolvers::UUID.new.resolve(new_request, argument).should be_nil
    end

    it "some other type" do
      ATH::Arguments::Resolvers::UUID.new.resolve(new_request, ATH::Arguments::ArgumentMetadata(Int32).new "foo").should be_nil
      ATH::Arguments::Resolvers::UUID.new.resolve(new_request, ATH::Arguments::ArgumentMetadata(Int32?).new "foo").should be_nil
      ATH::Arguments::Resolvers::UUID.new.resolve(new_request, ATH::Arguments::ArgumentMetadata(Bool | String).new "foo").should be_nil
    end
    it "attribute exists but is not a string" do
      argument = ATH::Arguments::ArgumentMetadata(UUID).new "foo"
      request = new_request
      request.attributes.set "foo", 100

      ATH::Arguments::Resolvers::UUID.new.resolve(request, argument).should be_nil
    end

    it "attribute exists but is nil with a nullable argument" do
      argument = ATH::Arguments::ArgumentMetadata(UUID?).new "foo"
      request = new_request
      request.attributes.set "foo", nil

      ATH::Arguments::Resolvers::UUID.new.resolve(request, argument).should be_nil
    end

    it "with a valid value" do
      argument = ATH::Arguments::ArgumentMetadata(UUID).new "foo"

      uuid = UUID.random

      request = new_request
      request.attributes.set "foo", uuid.to_s

      ATH::Arguments::Resolvers::UUID.new.resolve(request, argument).should eq uuid
    end

    it "type a union of another type" do
      argument = ATH::Arguments::ArgumentMetadata(UUID | Int32).new "foo"
      request = new_request

      uuid = UUID.random

      request.attributes.set "foo", uuid.to_s

      ATH::Arguments::Resolvers::UUID.new.resolve(request, argument).should eq uuid
    end

    it "with a valid nilable value" do
      argument = ATH::Arguments::ArgumentMetadata(UUID?).new "foo"

      uuid = UUID.random

      request = new_request
      request.attributes.set "foo", uuid.to_s

      ATH::Arguments::Resolvers::UUID.new.resolve(request, argument).should eq uuid
    end

    it "with an invalid value" do
      argument = ATH::Arguments::ArgumentMetadata(UUID).new "foo"

      request = new_request
      request.attributes.set "foo", "foo"

      expect_raises ATH::Exceptions::BadRequest, "Parameter 'foo' with value 'foo' is not a valid 'UUID'." do
        ATH::Arguments::Resolvers::UUID.new.resolve request, argument
      end
    end
  end
end
