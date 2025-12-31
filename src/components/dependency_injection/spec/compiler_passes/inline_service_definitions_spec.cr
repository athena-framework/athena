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

# 9. Inlined service with array parameter containing inlined services
# This exercises the array handling code paths in inline_service_definitions.cr
module InlineArrayInterface
  abstract def value : Int32
end

@[ADI::Register]
class ArrayLeafService1
  include InlineArrayInterface

  def value : Int32
    10
  end
end

@[ADI::Register]
class ArrayLeafService2
  include InlineArrayInterface

  def value : Int32
    20
  end
end

# This service is private + single-use, so it gets inlined into ArrayParentClient
# It takes an array of inlined services, exercising array handling code paths
@[ADI::Register(_items: ["@array_leaf_service1", "@array_leaf_service2"])]
class ArrayMiddleService
  def initialize(@items : Array(InlineArrayInterface))
  end

  def total
    @items.sum(&.value)
  end
end

@[ADI::Register(public: true)]
class ArrayParentClient
  def initialize(@middle : ArrayMiddleService)
  end

  def total
    @middle.total
  end
end

# 10. Inlined service with calls: containing inlined service args
# This exercises the calls argument handling code paths
@[ADI::Register]
class CallsLeafService
  def value
    700
  end
end

# This service is private + single-use, gets inlined into CallsParentClient
# It uses calls: with an inlined service arg
@[ADI::Register(calls: [{"set_leaf", {calls_leaf_service}}])]
class CallsMiddleService
  getter leaf : CallsLeafService?

  def set_leaf(@leaf : CallsLeafService)
  end

  def value
    @leaf.not_nil!.value
  end
end

@[ADI::Register(public: true)]
class CallsParentClient
  def initialize(@middle : CallsMiddleService)
  end

  def value
    @middle.value
  end
end

# 11. Service with no-arg method call
# This exercises the no-args branch in define_getters.cr
@[ADI::Register(public: true, calls: [{"init"}])]
class NoArgCallClient
  getter initialized = false

  def init
    @initialized = true
  end
end

# 12. Inlined service with array containing mix of inlined and non-inlined services
@[ADI::Register(public: true)]
class MixedArrayPublicService
  include InlineArrayInterface

  def value : Int32
    100
  end
end

@[ADI::Register]
class MixedArrayInlinedService
  include InlineArrayInterface

  def value : Int32
    50
  end
end

# This service is private + single-use, so gets inlined
# Its array has a mix: one inlined service, one public (non-inlined) service
@[ADI::Register(_items: ["@mixed_array_inlined_service", "@mixed_array_public_service"])]
class MixedArrayMiddleService
  def initialize(@items : Array(InlineArrayInterface))
  end

  def total
    @items.sum(&.value)
  end
end

@[ADI::Register(public: true)]
class MixedArrayClient
  def initialize(@middle : MixedArrayMiddleService)
  end

  def total
    @middle.total
  end
end

# 13. Out-of-order dependency to exercise re-queue logic
# Define the dependent service BEFORE its dependency to test re-queue
# OrderingMiddleService depends on OrderingDepService but is defined first

@[ADI::Register]
class OrderingMiddleService
  def initialize(@dep : OrderingDepService)
  end

  def value
    @dep.value
  end
end

@[ADI::Register]
class OrderingDepService
  def value
    999
  end
end

@[ADI::Register(public: true)]
class OrderingTestClient
  def initialize(@middle : OrderingMiddleService)
  end

  def value
    @middle.value
  end
end

# 14. Out-of-order array element dependency
# ArrayOrderingMiddle depends on ArrayOrderingDep via array, but is defined first
@[ADI::Register(_items: ["@array_ordering_dep"])]
class ArrayOrderingMiddle
  def initialize(@items : Array(InlineArrayInterface))
  end

  def total
    @items.sum(&.value)
  end
end

@[ADI::Register]
class ArrayOrderingDep
  include InlineArrayInterface

  def value : Int32
    777
  end
end

@[ADI::Register(public: true)]
class ArrayOrderingClient
  def initialize(@middle : ArrayOrderingMiddle)
  end

  def total
    @middle.total
  end
end

# 15. Out-of-order call arg dependency
# CallOrderingMiddle has call with arg CallOrderingDep, but is defined first
@[ADI::Register(calls: [{"set_dep", {call_ordering_dep}}])]
class CallOrderingMiddle
  getter dep : CallOrderingDep?

  def set_dep(@dep : CallOrderingDep)
  end

  def value
    @dep.not_nil!.value
  end
end

@[ADI::Register]
class CallOrderingDep
  def value
    888
  end
end

@[ADI::Register(public: true)]
class CallOrderingClient
  def initialize(@middle : CallOrderingMiddle)
  end

  def value
    @middle.value
  end
end

# 16. Inlined service with call arg that is NOT an inlined service
@[ADI::Register(public: true)]
class NonInlinedCallArgService
  def value
    800
  end
end

# This service is private + single-use, gets inlined
# Its call arg references a PUBLIC service (not inlined)
@[ADI::Register(calls: [{"set_dep", {non_inlined_call_arg_service}}])]
class NonInlinedCallArgMiddleService
  getter dep : NonInlinedCallArgService?

  def set_dep(@dep : NonInlinedCallArgService)
  end

  def value
    @dep.not_nil!.value
  end
end

@[ADI::Register(public: true)]
class NonInlinedCallArgClient
  def initialize(@middle : NonInlinedCallArgMiddleService)
  end

  def value
    @middle.value
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

  it "supports inlined services with array parameters containing inlined services" do
    ADI.container.array_parent_client.total.should eq 30
  end

  it "supports inlined services with calls using inlined service args" do
    ADI.container.calls_parent_client.value.should eq 700
  end

  it "supports method calls without arguments" do
    ADI.container.no_arg_call_client.initialized.should be_true
  end

  it "supports inlined services with mixed array params (inlined and non-inlined)" do
    ADI.container.mixed_array_client.total.should eq 150
  end

  it "supports inlined services with non-inlined call args" do
    ADI.container.non_inlined_call_arg_client.value.should eq 800
  end

  it "handles out-of-order dependency processing" do
    ADI.container.ordering_test_client.value.should eq 999
  end

  it "handles out-of-order array element dependencies" do
    ADI.container.array_ordering_client.total.should eq 777
  end

  it "handles out-of-order call arg dependencies" do
    ADI.container.call_ordering_client.value.should eq 888
  end
end
