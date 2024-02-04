require "../spec_helper"

ADI.bind id, 20
ADI.bind name, "Fred"

# Overrides previous value
ADI.bind value, 66
ADI.bind value, 88

# Mixed type
ADI.bind value : Float32, 3.14
ADI.bind value : Float64, 99.99

@[ADI::Register(
  public: true,
  _id: 30,
)]
class BindingsPriorityClient
  def initialize(
    id : Int64,    # Ann has highest priority
    name : String, # Global bind 2nd highest priority
    alive : Bool,  # Autoconfigure lowest priority
    value : Float32
  )
    id.should eq 30
    name.should eq "Fred"
    alive.should be_true
    value.should eq 3.14_f32
  end
end

ADI.auto_configure BindingsPriorityClient, {
  bind: {
    id:    10,
    name:  "Jim",
    alive: true,
  },
}

@[ADI::Register]
class SomeClassService
  getter value : Int32 = 123

  def_equals
end

@[ADI::Register]
record SomeStructService, name : String = "Fred"

@[ADI::Register(
  public: true,
  _some_service: "@some_class_service",
  _some_parameter: "%app.domain%",
  _service_hash: {
    "class"  => "@some_class_service",
    "struct" => "@some_struct_service",
  },
  _service_array: [
    "@some_class_service",
    "@some_struct_service",
  ]
)]
class BindingsClient
  def initialize(
    some_service : SomeClassService,
    some_parameter : String,
    service_hash : Hash(String, SomeClassService | SomeStructService),
    service_array : Array(SomeClassService | SomeStructService),
    value : Float64,
    proxy_service : ADI::Proxy(SomeStructService)
  )
    some_service.value.should eq 123
    some_parameter.should eq "google.com"
    service_hash.should eq({"class" => SomeClassService.new, "struct" => SomeStructService.new})
    service_array.should eq [SomeClassService.new, SomeStructService.new]
    value.should eq 99.99
    proxy_service.should eq SomeStructService.new
  end
end

@[ADI::Register(public: true)]
class Bindings2Client
  def initialize(
    value,
    proxy_service : SomeStructService
  )
    value.should eq 88
    proxy_service.should eq SomeStructService.new
  end
end

alias MyCustomInt = Int32

ADI.bind aliased_number : Int32, 123
ADI.bind aliased_number, 456

@[ADI::Register(public: true)]
record AliasedBindingClient, aliased_number : MyCustomInt

describe ADI::ServiceContainer do
  it "resolves bindings in proper order Annotation > Global > AutoConfigure" do
    ADI.container.bindings_priority_client
  end

  it "resolves parameter and service references" do
    ADI.container.bindings_client
    ADI.container.bindings2_client
  end

  it "resolves typed bindings when types differ" do
    ADI.container.aliased_binding_client.aliased_number.should eq 123
  end
end
