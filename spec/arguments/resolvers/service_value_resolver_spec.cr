require "../../spec_helper"

describe ART::Arguments::Resolvers::Service do
  it ".priority" do
    ART::Arguments::Resolvers::Service.priority.should eq -50
  end

  describe "#supports" do
    it "with an existing service" do
      argument = ART::Arguments::ArgumentMetadata(ART::RequestStore).new("request_store", false, false)

      ART::Arguments::Resolvers::Service.new.supports?(new_request, argument).should be_true
    end

    it "with a non existing service" do
      argument = ART::Arguments::ArgumentMetadata(ART::RequestStore).new("fooobar", false, false)

      ART::Arguments::Resolvers::Service.new.supports?(new_request, argument).should be_false
    end
  end

  describe "#resolve" do
    it "that is able to be resolved" do
      argument = ART::Arguments::ArgumentMetadata(ART::RequestStore).new("request_store", false, false)

      ART::Arguments::Resolvers::Service.new.resolve(new_request, argument).should be_a ART::RequestStore
    end
  end
end
