require "../../spec_helper"

class CustomRequest < ART::Request
end

describe ART::Arguments::Resolvers::Request do
  describe "#supports" do
    it ART::Request do
      argument = ART::Arguments::ArgumentMetadata(ART::Request).new("id", false, false)

      ART::Arguments::Resolvers::Request.new.supports?(new_request, argument).should be_true
    end

    it "subclass" do
      argument = ART::Arguments::ArgumentMetadata(CustomRequest).new("id", false, false)

      ART::Arguments::Resolvers::Request.new.supports?(new_request, argument).should be_true
    end

    it TestController do
      argument = ART::Arguments::ArgumentMetadata(TestController).new("id", false, false)

      ART::Arguments::Resolvers::Request.new.supports?(new_request, argument).should be_false
    end
  end

  describe "#resolve" do
    it "with a default value" do
      request = new_request

      ART::Arguments::Resolvers::Request.new.resolve(request, new_argument).should be request
    end
  end
end
