require "./dependency_injection_spec_helper"

class UnknownService < Athena::DI::ClassService
end

abstract class FakeServices < Athena::DI::ClassService
end

@[Athena::DI::Register]
class FakeService < FakeServices
end

@[Athena::DI::Register(name: "custom_fake")]
class CustomFooFakeService < FakeServices
end

@[Athena::DI::Register("GOOGLE", "Google", name: "google", tags: ["feed_partner", "partner"])]
@[Athena::DI::Register("FACEBOOK", "Facebook", name: "facebook", tags: ["partner"])]
struct FeedPartner < Athena::DI::StructService
  getter id : String
  getter name : String

  def initialize(@id : String, @name : String); end
end

@[Athena::DI::Register("!partner")]
class PartnerManager < Athena::DI::ClassService
  getter partners

  def initialize(@partners : Array(FeedPartner))
  end
end

class PartnerParamConverter
  include Athena::DI::Injectable

  getter manager

  def initialize(@manager : PartnerManager); end
end

@[Athena::DI::Register]
class Store < Athena::DI::ClassService
  property name : String = "Jim"
end

class FakeStore < Store
  property name : String = "TEST"
end

class SomeClass
  include Athena::DI::Injectable

  getter store : Store

  def initialize(@store : Store); end
end

class OtherClass
  include Athena::DI::Injectable

  getter store : Store
  getter id : String

  def initialize(@store : Store, @id : String); end
end

@[Athena::DI::Register("@blah", "a_string", "@a_service")]
class AService2 < Athena::DI::ClassService
  getter blah : Blah
  getter foo : String
  getter ase : AService

  def initialize(@blah : Blah, @foo : String, @ase : AService); end
end

@[Athena::DI::Register("@blah", "@some_service")]
class AService < Athena::DI::ClassService
  def initialize(@blah : Blah, @foo : Foo); end
end

@[Athena::DI::Register("@some_service", 99_i64)]
class Blah < Athena::DI::ClassService
  getter foo : Foo
  getter val : Int64

  def initialize(@foo : Foo, @val : Int64); end
end

@[Athena::DI::Register(name: "some_service")]
class Foo < Athena::DI::ClassService
  property name = "Bob"
end

class FooBar
  include Athena::DI::Injectable

  getter serv : AService2

  def initialize(@serv : AService2); end
end

describe Athena::DI::ServiceContainer do
  describe "#get" do
    describe "by type and name" do
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

    describe "by type" do
      it "should return an array of services with that type" do
        services = CONTAINER.get FakeServices
        services.size.should eq 2
        services[0].should be_a FakeService
        services[1].should be_a CustomFooFakeService
      end
    end
  end

  describe "#has" do
    describe "when the service has been registered" do
      it "should return true" do
        CONTAINER.has("blah").should be_true
      end
    end

    describe "when the service has been registered" do
      it "should return false" do
        CONTAINER.has("i_do_not_exist").should be_false
      end
    end
  end

  describe "#resolve" do
    describe "when there are no services with the type" do
      it "should raise an exception" do
        expect_raises Exception, "Could not resolve a service with type 'UnknownService' and name of 'unknown_service'." { CONTAINER.resolve UnknownService, "unknown_service" }
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

    it "should return the service with the given tag" do
      CONTAINER.tagged("fake_tag").should eq [] of Athena::DI::Service
    end
  end

  describe "auto injection" do
    describe "with only services" do
      it "should inject an instance of the Store class" do
        klass = SomeClass.new
        klass.store.should be_a Store
        klass.store.name.should eq "Jim"
      end
    end

    describe "with a non service argument" do
      it "should auto inject the store" do
        klass = OtherClass.new id: "FOO"
        klass.id.should eq "FOO"
        klass.store.should be_a Store
        klass.store.name.should eq "Jim"
      end
    end

    describe "when overriding the service" do
      it "should use the mocked service" do
        klass = OtherClass.new id: "FOO", store: FakeStore.new
        klass.id.should eq "FOO"
        klass.store.should be_a FakeStore
        klass.store.name.should eq "TEST"
      end
    end

    describe "with other required services" do
      it "should inject an instance of the Store class" do
        klass = FooBar.new
        klass.serv.blah.should be_a Blah
        klass.serv.foo.should eq "a_string"
        klass.serv.ase.should be_a AService
      end
    end

    describe "when injecting tagged services" do
      it "should inject all services with that tag" do
        klass = PartnerParamConverter.new
        klass.manager.partners.size.should eq 2

        klass.manager.partners[0].id.should eq "GOOGLE"
        klass.manager.partners[1].id.should eq "FACEBOOK"
      end
    end
  end
end
