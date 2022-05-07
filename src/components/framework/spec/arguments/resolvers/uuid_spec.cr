require "../../spec_helper"

describe ATH::Arguments::Resolvers::UUID do
  describe "#supports?" do
    describe ::UUID do
      describe "exists in request attributes" do
        it "is not a string" do
          argument = ATH::Arguments::ArgumentMetadata(UUID).new "foo"
          request = new_request
          request.attributes.set "foo", 100

          ATH::Arguments::Resolvers::UUID.new.supports?(request, argument).should be_false
        end

        it "type is nilable and the value is nil" do
          argument = ATH::Arguments::ArgumentMetadata(UUID?).new "foo"
          request = new_request
          request.attributes.set "foo", nil

          ATH::Arguments::Resolvers::UUID.new.supports?(request, argument).should be_false
        end

        it "type is nilable" do
          argument = ATH::Arguments::ArgumentMetadata(UUID?).new "foo"
          request = new_request
          request.attributes.set "foo", UUID.random.to_s

          ATH::Arguments::Resolvers::UUID.new.supports?(request, argument).should be_true
        end

        it "type a union of another type" do
          argument = ATH::Arguments::ArgumentMetadata(UUID | Int32).new "foo"
          request = new_request
          request.attributes.set "foo", UUID.random.to_s

          ATH::Arguments::Resolvers::UUID.new.supports?(request, argument).should be_true
        end
      end

      it "does not exist in request attributes" do
        argument = ATH::Arguments::ArgumentMetadata(UUID).new "foo"
        ATH::Arguments::Resolvers::UUID.new.supports?(new_request, argument).should be_false
      end
    end

    it "some other type" do
      ATH::Arguments::Resolvers::UUID.new.supports?(new_request, ATH::Arguments::ArgumentMetadata(Int32).new "foo").should be_false
      ATH::Arguments::Resolvers::UUID.new.supports?(new_request, ATH::Arguments::ArgumentMetadata(Int32?).new "foo").should be_false
      ATH::Arguments::Resolvers::UUID.new.supports?(new_request, ATH::Arguments::ArgumentMetadata(Bool | String).new "foo").should be_false
    end
  end

  describe "#resolve" do
    it "with a valid value" do
      argument = ATH::Arguments::ArgumentMetadata(UUID).new "foo"

      uuid = UUID.random

      request = new_request
      request.attributes.set "foo", uuid.to_s

      ATH::Arguments::Resolvers::UUID.new.resolve(request, argument).should eq uuid
    end

    it "with an invalild value" do
      argument = ATH::Arguments::ArgumentMetadata(UUID).new "foo"

      request = new_request
      request.attributes.set "foo", "foo"

      ex = expect_raises ATH::Exceptions::BadRequest, "Parameter 'foo' with value 'foo' is not a valid 'UUID'." do
        ATH::Arguments::Resolvers::UUID.new.resolve request, argument
      end

      ex.cause.should be_a ArgumentError
    end
  end
end
