require "../../spec_helper"

describe ATH::Arguments::Resolvers::Request do
  describe "#resolve" do
    it TestController do
      argument = ATH::Arguments::ArgumentMetadata(TestController).new "foo"

      ATH::Arguments::Resolvers::Request.new.resolve(new_request, argument).should be_nil
    end

    it "with a valid value" do
      argument = ATH::Arguments::ArgumentMetadata(ATH::Request).new "foo"
      request = new_request

      ATH::Arguments::Resolvers::Request.new.resolve(request, argument).should be request
    end
  end
end
