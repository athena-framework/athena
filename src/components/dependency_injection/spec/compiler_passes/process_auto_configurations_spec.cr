require "../spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
    ADI::ServiceContainer.new
  CR
end

private PARTNER_TAG = "partner"

enum Status
  Active
  Inactive
end

@[ADI::Register(_id: 1, name: "google", tags: [{name: PARTNER_TAG, priority: 5}])]
@[ADI::Register(_id: 2, name: "facebook", tags: [PARTNER_TAG])]
@[ADI::Register(_id: 3, name: "yahoo", tags: [{name: "partner", priority: 10}])]
@[ADI::Register(_id: 4, name: "microsoft", tags: [PARTNER_TAG])]
struct FeedPartner
  getter id

  def initialize(@id : Int32); end
end

@[ADI::Register(_services: "!partner", public: true)]
class PartnerClient
  getter services

  def initialize(@services : Array(FeedPartner))
  end
end

@[ADI::Register(_services: "!partner", public: true)]
class PartnerNamedDefaultClient
  getter services
  getter status

  def initialize(
    @services : Array(FeedPartner),
    @status : Status = Status::Active,
  )
  end
end

@[ADI::Register(_services: "!partner", public: true)]
record ProxyTagClient, services : Array(ADI::Proxy(FeedPartner))

OTHER_TAG = "foo.bar"

@[ADI::Autoconfigure(tags: [OTHER_TAG])]
module Test; end

@[ADI::Autoconfigure(public: true)]
module PublicService; end

@[ADI::Register]
@[ADI::Autoconfigure(tags: ["config"])]
class MultipleTags
  include Test
end

@[ADI::Register]
class SingleTag
  include Test
end

@[ADI::Register(_services: "!foo.bar", public: true)]
record OtherTagClient, services : Array(Test)

@[ADI::Register(_services: "!config", public: true)]
record ConfigTagClient, services : Array(MultipleTags)

@[ADI::Register]
record AutoConfiguredPublicService do
  include PublicService
end

STRING_UNUSED_TAG2 = "string_unused_tag2"
STRING_UNUSED_TAG3 = "string_unused_tag3"
STRING_UNUSED_TAG4 = "string_unused_tag4"

@[ADI::Autoconfigure(tags: ["unused_tag"])]
module UnusedInterface; end

@[ADI::Autoconfigure(tags: [STRING_UNUSED_TAG2])]
module UnusedInterface2; end

@[ADI::Autoconfigure(tags: STRING_UNUSED_TAG3)]
module UnusedInterface3; end

@[ADI::Autoconfigure(tags: [{name: STRING_UNUSED_TAG4}])]
module UnusedInterface4; end

@[ADI::Autoconfigure(tags: [{name: "string_unused_tag5"}])]
module UnusedInterface5; end

@[ADI::Register(_services: "!unused_tag", public: true)]
record UnusedTagClient, services : Array(UnusedInterface)

@[ADI::Autoconfigure(calls: [{"foo", {6}}, {"foo", {3}}, {"foo"}])]
module CallInterface; end

@[ADI::Register(public: true)]
class CallAutoconfigureClient
  include CallInterface

  getter values = [] of Int32

  def foo(value : Int32 = 1)
    @values << value
  end
end

@[ADI::AutoconfigureTag]
module Namespace::FQNTagInterface; end

@[ADI::AutoconfigureTag("foo")]
module Namespace::ExplicitTagInterface; end

BAR_TAG = "bar"

@[ADI::AutoconfigureTag(BAR_TAG)]
module Namespace::ExplicitTagConstInterface; end

@[ADI::Register]
record FQNService1 do
  include Namespace::FQNTagInterface
  include Namespace::ExplicitTagConstInterface
end

@[ADI::Register]
record FQNService2 do
  include Namespace::FQNTagInterface
  include Namespace::ExplicitTagInterface
end

@[ADI::Register(public: true, _services: "!Namespace::FQNTagInterface")]
class FQNTagClient
  getter services : Array(Namespace::FQNTagInterface)

  def initialize(@services : Array(Namespace::FQNTagInterface)); end
end

@[ADI::Register(public: true, _services: "!foo")]
class FQNTagNamedClient
  getter services : Array(Namespace::ExplicitTagInterface)

  def initialize(@services : Array(Namespace::ExplicitTagInterface)); end
end

@[ADI::Register(public: true, _services: "!bar")]
class FQNTagConstClient
  getter services : Array(Namespace::ExplicitTagConstInterface)

  def initialize(@services : Array(Namespace::ExplicitTagConstInterface)); end
end

@[ADI::Register(public: true)]
class FQNTaggedIteratorClient
  getter services

  def initialize(@[ADI::TaggedIterator] @services : Enumerable(Namespace::FQNTagInterface)); end
end

@[ADI::Register(public: true)]
class FQNTaggedIteratorNamedClient
  getter services

  def initialize(@[ADI::TaggedIterator("Namespace::FQNTagInterface")] @services : Enumerable(Namespace::FQNTagInterface)); end
end

NAMESPACE_TAG = "Namespace::FQNTagInterface"

@[ADI::Register(public: true)]
class FQNTaggedIteratorNamedConstClient
  getter services

  def initialize(@[ADI::TaggedIterator(NAMESPACE_TAG)] @services : Enumerable(Namespace::FQNTagInterface)); end
end

@[ADI::Autoconfigure(tags: ["non-service-abstract"])]
abstract struct NonServiceAbstract; end

@[ADI::Register]
record NonServiceChild1 < NonServiceAbstract

@[ADI::Register]
record NonServiceChild2 < NonServiceAbstract

@[ADI::Register(public: true, _services: "!non-service-abstract")]
class NonServiceAbstractClient
  getter services : Array(NonServiceAbstract)

  def initialize(@services : Array(NonServiceAbstract)); end
end

@[ADI::Autoconfigure(constructor: "create", public: true)]
abstract class AutoConfigureConstructor; end

@[ADI::Register(public: true)]
class ConstructorOne < AutoConfigureConstructor
  getter num

  def self.create : self
    new 123
  end

  private def initialize(@num : Int32); end
end

@[ADI::Register(_id: 999, public: true)]
class ConstructorTwo < AutoConfigureConstructor
  getter num

  def self.create(id : Int32) : self
    new id
  end

  private def initialize(@num : Int32); end
end

describe ADI::ServiceContainer::ProcessAutoconfigureAnnotations do
  describe "compiler errors", tags: "compiled" do
    describe "tags" do
      it "errors if the `tags` field is not of a valid type" do
        assert_error "Tags for 'foo' must be an 'ArrayLiteral', got 'NumberLiteral'.", <<-CR
          @[ADI::Register(tags: 123)]
          record Foo
        CR
      end

      it "errors if the `tags` field on the auto configuration is not of a valid type" do
        assert_error "Tags for auto configuration of 'Test' must be an 'ArrayLiteral', got 'NumberLiteral'.", <<-CR
          @[ADI::Autoconfigure(tags: 123)]
          module Test; end

          @[ADI::Register]
          record Foo do
            include Test
          end
        CR
      end

      describe ADI::TaggedIterator do
        it "errors if used with unsupported collection type" do
          assert_error "Failed to register service 'fqn_tagged_iterator_named_client' (FQNTaggedIteratorNamedClient). Collection parameter '@[ADI::TaggedIterator] services : Set(String)' type must be one of `Indexable`, `Iterator`, or `Enumerable`. Got 'Set'.", <<-CR
            @[ADI::Register]
            class FQNTaggedIteratorNamedClient
              getter services

              def initialize(@[ADI::TaggedIterator] @services : Set(String)); end
            end
          CR
        end
      end
    end

    describe "calls" do
      it "errors if the method of a call is empty" do
        assert_error "Method name cannot be empty.", <<-CR
          @[ADI::Autoconfigure(calls: [{""}])]
          module Test; end

          @[ADI::Register]
          record Foo do
            include Test
          end
        CR
      end

      it "errors if the method does not exist on the type" do
        assert_error "Failed to auto register service for 'foo' (Foo). Call references non-existent method 'foo'.", <<-CR
          @[ADI::Autoconfigure(calls: [{"foo"}])]
          module Test; end

          @[ADI::Register]
          record Foo do
            include Test
          end
        CR
      end
    end
  end

  describe "tags" do
    it "injects all services with that tag, ordering based on priority" do
      services = ADI.container.partner_client.services
      services[0].id.should eq 3
      services[1].id.should eq 1
      services[2].id.should eq 2
      services[3].id.should eq 4
    end

    it "also allows the service to still have defaults after the tagged services argument" do
      service = ADI.container.partner_named_default_client
      service.services.size.should eq 4
      service.status.should eq Status::Active
    end

    it "converts each tagged service into a proxy" do
      services = ADI.container.proxy_tag_client.services
      services[0].id.should eq 3
      services[1].id.should eq 1
      services[2].id.should eq 2
      services[3].id.should eq 4
    end

    it "applies tags from auto_configure" do
      ADI.container.other_tag_client.services.size.should eq 2
      ADI.container.config_tag_client.services.size.should eq 1
    end

    describe ADI::AutoconfigureTag do
      it "without tag" do
        ADI.container.fqn_tag_client.services.should eq [FQNService1.new, FQNService2.new]
      end

      it "with tag name" do
        ADI.container.fqn_tag_named_client.services.should eq [FQNService2.new]
      end

      it "with tag name const" do
        ADI.container.fqn_tag_const_client.services.should eq [FQNService1.new]
      end
    end

    describe ADI::TaggedIterator do
      it "without tag name" do
        collection = ADI.container.fqn_tagged_iterator_client.services
        collection.should be_a Iterator(Namespace::FQNTagInterface)
        collection.map(&.itself).should eq [FQNService1.new, FQNService2.new]
      end

      it "with tag name" do
        collection = ADI.container.fqn_tagged_iterator_named_client.services
        collection.should be_a Iterator(Namespace::FQNTagInterface)
        collection.map(&.itself).should eq [FQNService1.new, FQNService2.new]
      end

      it "with tag name as const" do
        collection = ADI.container.fqn_tagged_iterator_named_const_client.services
        collection.should be_a Iterator(Namespace::FQNTagInterface)
        collection.map(&.itself).should eq [FQNService1.new, FQNService2.new]
      end
    end

    it "handles a non service abstract parent type with service child types" do
      ADI.container.non_service_abstract_client.services.should eq [NonServiceChild1.new, NonServiceChild2.new]
    end

    it "provides an empty array if there were no services configured with the desired tag" do
      ADI.container.unused_tag_client.services.should be_empty
    end
  end

  it "allows making a service public" do
    ADI.container.auto_configured_public_service.should be_a AutoConfiguredPublicService
  end

  it "allows defining calls" do
    ADI.container.call_autoconfigure_client.values.should eq [6, 3, 1]
  end

  it "allows specifying the constructor" do
    ADI.container.constructor_one.num.should eq 123
    ADI.container.constructor_two.num.should eq 999
  end
end
