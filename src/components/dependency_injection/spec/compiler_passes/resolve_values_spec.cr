require "../spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
    ADI::ServiceContainer.new
  CR
end

module ResolveValuePriorityInterface; end

@[ADI::Register]
record ServicePriorityOne do
  include ResolveValuePriorityInterface
end

@[ADI::Register]
record ServicePriorityTwo do
  include ResolveValuePriorityInterface
end

@[ADI::Register(alias: ResolveValuePriorityInterface)]
record ServicePriorityFour do
  include ResolveValuePriorityInterface
end

@[ADI::Register]
record ServicePriorityThree

@[ADI::Register(_ann_bind: 1000, public: true)]
class ValuePriorityService
  getter ann_bind, global_bind, auto_configure_bind, default_value, nilable_type

  def initialize(
    ann_bind : Int32,
    global_bind : Int32,
    auto_configure_bind : Int32,
    nilable_type : Int32?,
    default_value : Int32 = 700
  )
    ann_bind.should eq 1000
    global_bind.should eq 900
    auto_configure_bind.should eq 800
    nilable_type.should be_nil
    default_value.should eq 700
  end
end

ADI.auto_configure ValuePriorityService, {bind: {ann_bind: 800, global_bind: 800, auto_configure_bind: 800}}
ADI.bind ann_bind : Int32, 900
ADI.bind global_bind : Int32, 900

@[ADI::Register(_alias_overridden_by_ann_bind: "@service_priority_one", public: true)]
class ServiceValuePriorityService
  getter explicit_auto_wire, interface_service_matches_name, default_alias, alias_overridden_by_ann_bind

  def initialize(
    explicit_auto_wire : ServicePriorityThree,
    service_priority_two : ResolveValuePriorityInterface,
    default_alias : ResolveValuePriorityInterface,
    alias_overridden_by_ann_bind : ResolveValuePriorityInterface,
    alias_overridden_by_global_bind : ResolveValuePriorityInterface,
    alias_overridden_by_auto_configure_bind : ResolveValuePriorityInterface
  )
    explicit_auto_wire.should be_a ServicePriorityThree
    service_priority_two.should be_a ServicePriorityTwo
    default_alias.should be_a ServicePriorityFour
    alias_overridden_by_ann_bind.should be_a ServicePriorityOne
    alias_overridden_by_global_bind.should be_a ServicePriorityOne
    alias_overridden_by_auto_configure_bind.should be_a ServicePriorityTwo
  end
end

ADI.auto_configure ServiceValuePriorityService, {bind: {alias_overridden_by_auto_configure_bind: "@service_priority_two"}}
ADI.bind alias_overridden_by_global_bind : ResolveValuePriorityInterface, "@service_priority_one"

describe ADI::ServiceContainer::ResolveValues do
  describe "compiler errors", tags: "compiled" do
    it "errors if a service string reference doesn't map to a known service" do
      assert_error "Failed to register service 'foo'. Argument 'id : Int32' references undefined service 'bar'.", <<-CR
        @[ADI::Register(_id: "@bar")]
        record Foo, id : Int32
      CR
    end

    it "errors if a service string reference doesn't map to a known tag" do
      assert_error "Failed to register service 'foo'. Argument 'id : Int32' references undefined tag 'bar'.", <<-CR
        @[ADI::Register(_id: "!bar")]
        record Foo, id : Int32
      CR
    end
  end

  it "resolves the values with the expected priority" do
    ADI.container.value_priority_service
  end

  it "resolves service references with the expected priority" do
    ADI.container.service_value_priority_service
  end
end
