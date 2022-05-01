require "../../spec_helper"

describe ATH::Arguments::Resolvers::RequestAttribute do
  describe "#supports?" do
    it "that exists in the request attributes" do
      request = new_request
      request.attributes.set "id", 1

      ATH::Arguments::Resolvers::RequestAttribute.new.supports?(request, new_argument).should be_true
    end

    it "that does not exist in the request attributes" do
      ATH::Arguments::Resolvers::RequestAttribute.new.supports?(new_request, new_argument).should be_false
    end
  end

  describe "#resolve" do
    it "that exists in the request attributes" do
      request = new_request
      request.attributes.set "id", 1

      ATH::Arguments::Resolvers::RequestAttribute.new.resolve(request, new_argument).should eq 1
    end

    describe "that needs to be converted" do
      it String do
        argument = ATH::Arguments::ArgumentMetadata(Int32).new "id"

        request = new_request
        request.attributes.set "id", "1"

        ATH::Arguments::Resolvers::RequestAttribute.new.resolve(request, argument).should eq 1
      end

      it Bool do
        argument = ATH::Arguments::ArgumentMetadata(Bool).new "id"

        request = new_request
        request.attributes.set "id", "false"

        ATH::Arguments::Resolvers::RequestAttribute.new.resolve(request, argument).should be_false
      end

      it "that fails conversion" do
        argument = ATH::Arguments::ArgumentMetadata(Int32).new "id"

        request = new_request
        request.attributes.set "id", "foo"

        expect_raises ATH::Exceptions::BadRequest, "Parameter 'id' with value 'foo' could not be converted into a valid 'Int32'." do
          ATH::Arguments::Resolvers::RequestAttribute.new.resolve request, argument
        end
      end
    end
  end
end
