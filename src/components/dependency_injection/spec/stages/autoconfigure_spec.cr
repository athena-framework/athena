require "../spec_helper"

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

@[ADI::Register(_services: "!foo.bar", public: true)]
record OtherTagClient, services : Array(Test)

@[ADI::Register(_services: "!config", public: true)]
record ConfigTagClient, services : Array(MultipleTags)

describe ADI::ServiceContainer do
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
end
