require "../spec_helper"

# 1. Basic inlining: single-use private service
@[ADI::Register]
class BasicInlinedDep
  def value
    42
  end
end

@[ADI::Register(public: true)]
class BasicInlineClient
  def initialize(@dep : BasicInlinedDep)
  end

  def value
    @dep.value
  end
end

# 2. Nested inlining: chain of inlined services
@[ADI::Register]
class NestedInlineDep1
  def value
    1
  end
end

@[ADI::Register]
class NestedInlineDep2
  def initialize(@dep : NestedInlineDep1)
  end

  def value
    @dep.value + 1
  end
end

@[ADI::Register(public: true)]
class NestedInlineClient
  def initialize(@dep : NestedInlineDep2)
  end

  def value
    @dep.value
  end
end

# 3. Public alias target - should NOT be inlined
module InlineTestAliasInterface; end

@[ADI::Register]
@[ADI::AsAlias("inline_test_alias", public: true)]
class InlineAliasTargetService
  include InlineTestAliasInterface

  def value
    100
  end
end

@[ADI::Register(public: true)]
class InlineAliasClient
  def initialize(@dep : InlineAliasTargetService)
  end

  def value
    @dep.value
  end
end

# 4. Proxy target - should NOT be inlined
@[ADI::Register]
class InlineProxyTargetService
  def value
    200
  end
end

@[ADI::Register(public: true)]
class InlineProxyClient
  def initialize(@proxy : ADI::Proxy(InlineProxyTargetService))
  end

  def value
    @proxy.value
  end
end

# 5. Public service - should NOT be inlined
@[ADI::Register(public: true)]
class InlinePublicDepService
  def value
    300
  end
end

@[ADI::Register(public: true)]
class InlinePublicDepClient
  def initialize(@dep : InlinePublicDepService)
  end

  def value
    @dep.value
  end
end

# 6. Multiple references - should NOT be inlined
@[ADI::Register]
class InlineMultiRefService
  def value
    400
  end
end

@[ADI::Register(public: true)]
class InlineMultiRefClient1
  def initialize(@dep : InlineMultiRefService)
  end

  def value
    @dep.value
  end
end

@[ADI::Register(public: true)]
class InlineMultiRefClient2
  def initialize(@dep : InlineMultiRefService)
  end

  def value
    @dep.value + 1
  end
end

# 7. Factory method inlining
@[ADI::Register(factory: "create")]
class FactoryInlineService
  getter value : Int32

  def initialize(@value : Int32)
  end

  def self.create
    new(500)
  end
end

@[ADI::Register(public: true)]
class FactoryInlineClient
  def initialize(@dep : FactoryInlineService)
  end

  def value
    @dep.value
  end
end

# 8. Calls argument inlining
@[ADI::Register]
class CallsInlineService
  def value
    600
  end
end

@[ADI::Register(public: true, calls: [{"set_service", {calls_inline_service}}])]
class CallsInlineClient
  getter service : CallsInlineService?

  def set_service(@service : CallsInlineService)
  end
end

describe ADI::ServiceContainer::InlineServiceDefinitions do
  it "inlines single-use private services" do
    ADI.container.basic_inline_client.value.should eq 42
  end

  it "supports nested inlined services" do
    ADI.container.nested_inline_client.value.should eq 2
  end

  it "works with public alias targets" do
    ADI.container.inline_alias_client.value.should eq 100
  end

  it "works with proxy targets" do
    ADI.container.inline_proxy_client.value.should eq 200
  end

  it "works with public services as dependencies" do
    ADI.container.inline_public_dep_client.value.should eq 300
  end

  it "works with multi-referenced services" do
    ADI.container.inline_multi_ref_client1.value.should eq 400
    ADI.container.inline_multi_ref_client2.value.should eq 401
  end

  it "supports factory methods for inlined services" do
    ADI.container.factory_inline_client.value.should eq 500
  end

  it "supports inlined services passed via calls" do
    ADI.container.calls_inline_client.service.not_nil!.value.should eq 600
  end
end
