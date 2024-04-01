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
    @status : Status = Status::Active
  )
  end
end

@[ADI::Register(_services: "!partner", public: true)]
record ProxyTagClient, services : Array(ADI::Proxy(FeedPartner))

OTHER_TAG = "foo.bar"

module Test; end

module PublicService; end

@[ADI::Register]
class MultipleTags
  include Test
end

@[ADI::Register]
class SingleTag
  include Test
end

ADI.auto_configure MultipleTags, {tags: ["config"]}
ADI.auto_configure Test, {tags: [OTHER_TAG]}
ADI.auto_configure PublicService, {public: true}

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

module UnusedInterface; end

module UnusedInterface2; end

module UnusedInterface3; end

module UnusedInterface4; end

module UnusedInterface5; end

ADI.auto_configure UnusedInterface, {tags: ["unused_tag"]}
ADI.auto_configure UnusedInterface2, {tags: [STRING_UNUSED_TAG2]}
ADI.auto_configure UnusedInterface3, {tags: STRING_UNUSED_TAG3}
ADI.auto_configure UnusedInterface4, {tags: [{name: STRING_UNUSED_TAG4}]}
ADI.auto_configure UnusedInterface5, {tags: [{name: "string_unused_tag5"}]}

@[ADI::Register(_services: "!unused_tag", public: true)]
record UnusedTagClient, services : Array(UnusedInterface)

module CallInterface; end

ADI.auto_configure CallInterface, {calls: [{"foo", {6}}, {"foo", {3}}, {"foo"}]}

@[ADI::Register(public: true)]
class CallAutoconfigureClient
  include CallInterface

  getter values = [] of Int32

  def foo(value : Int32 = 1)
    @values << value
  end
end

describe ADI::ServiceContainer::ProcessAutoConfigurations do
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
        module Test; end

        ADI.auto_configure Test, {tags: 123}

        @[ADI::Register]
        record Foo do
          include Test
        end
      CR
      end

      it "errors if not all tags have a `name` field" do
        assert_error "Failed to auto register service 'foo'. All tags must have a name.", <<-CR
        @[ADI::Register(tags: [{priority: 100}])]
        record Foo
      CR
      end

      it "errors if not all tags are of the proper type" do
        assert_error "Tag '100' must be a 'StringLiteral' or 'NamedTupleLiteral', got 'NumberLiteral'.", <<-CR
        @[ADI::Register(tags: [100])]
        record Foo
      CR
      end
    end

    describe "calls" do
      it "errors if the method of a call is empty" do
        assert_error "Method name cannot be empty.", <<-CR
          module Test; end

          ADI.auto_configure Test, {calls: [{""}]}

          @[ADI::Register]
          record Foo do
            include Test
          end
        CR
      end

      it "errors if the method does not exist on the type" do
        assert_error "Failed to auto register service for 'foo' (Foo). Call references non-existent method 'foo'.", <<-CR
          module Test; end

          ADI.auto_configure Test, {calls: [{"foo"}]}

          @[ADI::Register]
          record Foo do
            include Test
          end
        CR
      end
    end
  end

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

  it "provides an empty array if there were no services configured with the desired tag" do
    ADI.container.unused_tag_client.services.should be_empty
  end

  it "allows making a service public" do
    ADI.container.auto_configured_public_service.should be_a AutoConfiguredPublicService
  end

  it "allows defining calls" do
    ADI.container.call_autoconfigure_client.values.should eq [6, 3, 1]
  end
end
