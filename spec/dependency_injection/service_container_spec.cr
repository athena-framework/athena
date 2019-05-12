require "./dependency_injection_spec_helper"

class Foo < Athena::DI::ClassService
end

abstract class FakeServices < Athena::DI::ClassService
end

@[Athena::DI::Register]
class FakeService < FakeServices
end

@[Athena::DI::Register(name: "CustomFake")]
class CustomFooFakeService < FakeServices
end

@[Athena::DI::Register("GOOGLE", "Google", name: "google", tags: ["feed_partner", "partner"])]
@[Athena::DI::Register("FACEBOOK", "Facebook", name: "facebook", tags: ["partner"])]
struct FeedPartner < Athena::DI::StructService
  getter id : String
  getter name : String

  def initialize(@id : String, @name : String); end
end

describe Athena::DI::ServiceContainer do
  describe "#initialize" do
    it "should add the annotated services" do
      CONTAINER.services.size.should eq 4
      CONTAINER.services.has_key?("fake_service").should be_true
      fake_service = CONTAINER.services["fake_service"]
      fake_service.should be_a Athena::DI::Definition
      fake_service.service.should be_a FakeService
      fake_service.tags.should eq [] of String

      CONTAINER.services.has_key?("CustomFake").should be_true
      custom_fake = CONTAINER.services["CustomFake"]
      custom_fake.should be_a Athena::DI::Definition
      custom_fake.service.should be_a CustomFooFakeService
      custom_fake.tags.should eq [] of String

      CONTAINER.services.has_key?("google").should be_true
      google = CONTAINER.services["google"]
      google.should be_a Athena::DI::Definition
      google.service.should be_a FeedPartner
      google.tags.should eq ["feed_partner", "partner"]

      CONTAINER.services.has_key?("facebook").should be_true
      fakebook = CONTAINER.services["facebook"]
      fakebook.should be_a Athena::DI::Definition
      fakebook.service.should be_a FeedPartner
      fakebook.tags.should eq ["partner"]
    end
  end

  describe "#get" do
    describe "when the service exists" do
      it "should return the service with the given name" do
        CONTAINER.get("fake_service").should be_a FakeService
      end
    end

    describe "when the service does not exist" do
      it "should throw an exception" do
        expect_raises Exception, "No service with the name 'foobar' has been registered." { CONTAINER.get "foobar" }
      end
    end
  end

  describe "#resolve" do
    describe "when there are no services with the type" do
      it "should raise an exception" do
        expect_raises Exception, "No service with type 'Foo' has been registered." { CONTAINER.resolve Foo, "foo" }
      end
    end

    describe "when there is a single match" do
      it "should return the service" do
        CONTAINER.resolve(FakeService, "fake_service").should be_a FakeService
      end
    end

    describe "when there is are multiple matches" do
      describe "that does not match the name" do
        it "should raise an exception" do
          expect_raises Exception, "Could not resolve a service with type 'FeedPartner' and name of 'yahoo'." { CONTAINER.resolve FeedPartner, "yahoo" }
        end
      end

      describe "that matches a name" do
        it "should return the service" do
          service = CONTAINER.resolve(FeedPartner, "google").as(FeedPartner)
          service.should be_a FeedPartner
          service.id.should eq "GOOGLE"
        end
      end
    end

    describe Athena::DI::OfType do
      it "should return an array of services with that type" do
        services = CONTAINER.resolve Athena::DI::OfType(FakeServices)
        services.size.should eq 2
        services[0].should be_a FakeService
        services[1].should be_a CustomFooFakeService
      end
    end

    describe Athena::DI::Tagged do
      it "should return an array of services with that tag" do
        services = CONTAINER.resolve Athena::DI::Tagged.new "feed_partner"
        services.size.should eq 1

        google = services[0].as(FeedPartner)
        google.should be_a FeedPartner
        google.id.should eq "GOOGLE"
      end
    end
  end

  describe "#tagged" do
    it "should return the service with the given tag" do
      services = CONTAINER.tagged("partner")
      services.size.should eq 2

      google = services[0].as(FeedPartner)
      google.should be_a FeedPartner
      google.id.should eq "GOOGLE"

      facebook = services[1].as(FeedPartner)
      facebook.should be_a FeedPartner
      facebook.id.should eq "FACEBOOK"
    end

    it "should return the service with the given tag" do
      services = CONTAINER.tagged("feed_partner")
      services.size.should eq 1

      google = services[0].as(FeedPartner)
      google.should be_a FeedPartner
      google.id.should eq "GOOGLE"
    end
  end
end
