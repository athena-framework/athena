require "../../spec_helper"

describe ATH::Arguments::Resolvers::Request do
  describe "#supports" do
    it ATH::Request do
      argument = ATH::Arguments::ArgumentMetadata(ATH::Request).new("id", false)

      ATH::Arguments::Resolvers::Request.new.supports?(new_request, argument).should be_true
    end

    it TestController do
      argument = ATH::Arguments::ArgumentMetadata(TestController).new("id", false)

      ATH::Arguments::Resolvers::Request.new.supports?(new_request, argument).should be_false
    end
  end

  describe "#resolve" do
    it "with a default value" do
      request = new_request

      ATH::Arguments::Resolvers::Request.new.resolve(request, new_argument).should be request
    end
  end
end
