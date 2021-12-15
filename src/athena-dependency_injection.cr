require "./proxy"
require "./service_container"

require "athena-config"

require "compiler/crystal/macros"

# :nodoc:
class Fiber
  property container : ADI::ServiceContainer { ADI::ServiceContainer.new }
end

# Convenience alias to make referencing `Athena::DependencyInjection` types easier.
alias ADI = Athena::DependencyInjection

# Athena's Dependency Injection (DI) component, `ADI` for short, adds a service container layer to your project.  This allows useful objects, aka services, to be shared throughout the project.
# These objects live in a special class called the `ADI::ServiceContainer` (SC).
#
# The SC is lazily initialized on fibers; this allows the SC to be accessed anywhere within the project.  The `Athena::DependencyInjection.container` method will return the SC for the current fiber.
# Since the SC is defined on fibers, it allows for each fiber to have its own SC instance.  This can be useful for web frameworks as each request would have its own SC scoped to that request.
#
# * See `ADI::Register` for documentation on registering services.
#
# !!!tip
#     It is highly recommended to use interfaces as opposed to concrete types when defining the initializers for both services and non-services.
#
# Using interfaces allows changing the functionality of a type by just changing what service gets injected into it, such as via an alias.
# See this [blog post](https://dev.to/blacksmoke16/dependency-injection-in-crystal-2d66#plug-and-play) for an example of this.
module Athena::DependencyInjection
  VERSION = "0.3.2"

  private BINDINGS            = {} of Nil => Nil
  private AUTO_CONFIGURATIONS = {} of Nil => Nil

  # Applies the provided *options* to any registered service of the provided *type*.
  #
  # A common use case of this would be to apply a specific tag to all instances of an interface; thus preventing the need to manually apply the tag for each implementation.
  # This can be paired with `Athena::DependencyInjection.bind` to make working with tags easier.
  #
  # ### Example
  #
  # ```
  # module ConfigInterface; end
  #
  # # Automatically apply the `"config"` tag to all instances of `ConfigInterface`.
  # ADI.auto_configure ConfigInterface, {tags: ["config"]}
  #
  # @[ADI::Register]
  # record ConfigOne do
  #   include ConfigInterface
  # end
  #
  # @[ADI::Register]
  # record ConfigTwo do
  #   include ConfigInterface
  # end
  #
  # # Options supplied on the annotation itself override the auto configured options.
  # @[ADI::Register(tags: [] of String)]
  # record ConfigThree do
  #   include ConfigInterface
  # end
  #
  # @[ADI::Register(_configs: "!config", public: true)]
  # record ConfigClient, configs : Array(ConfigInterface)
  #
  # ADI.container.config_client.configs # => [ConfigOne(), ConfigTwo()]
  # ```
  macro auto_configure(type, options)
    {% AUTO_CONFIGURATIONS[type.resolve] = options %}
  end

  # Allows binding a *value* to a *key* in order to enable auto registration of that value.
  #
  # Bindings allow scalar values, or those that could not otherwise be handled via [service aliases][Athena::DependencyInjection::Register--aliasing-services], to be auto registered.
  # This allows those arguments to be defined once and reused, as opposed to using named arguments to manually specify them for each service.
  #
  # Bindings can also be declared with a type restriction to allow taking the type restriction of the argument into account.
  # Typed bindings are always checked first as the most specific type is always preferred.
  # If no typed bindings match the argument's type, then the last defined untyped bindings is used.
  #
  # ### Example
  #
  # ```
  # module ValueInterface; end
  #
  # @[ADI::Register(_value: 1, name: "value_one")]
  # @[ADI::Register(_value: 2, name: "value_two")]
  # @[ADI::Register(_value: 3, name: "value_three")]
  # record ValueService, value : Int32 do
  #   include ValueInterface
  # end
  #
  # # Untyped bindings
  # ADI.bind api_key, ENV["API_KEY"]
  # ADI.bind config, {id: 12_i64, active: true}
  # ADI.bind static_value, 123
  # ADI.bind odd_values, ["@value_one", "@value_three"]
  # ADI.bind value_arr, [true, true, false]
  #
  # # Typed bindings
  # ADI.bind value_arr : Array(Int32), [1, 2, 3]
  # ADI.bind value_arr : Array(Float64), [1.0, 2.0, 3.0]
  #
  # @[ADI::Register(public: true)]
  # record BindingClient,
  #   api_key : String,
  #   config : NamedTuple(id: Int64, active: Bool),
  #   static_value : Int32,
  #   odd_values : Array(ValueInterface)
  #
  # @[ADI::Register(public: true)]
  # record IntArr, value_arr : Array(Int32)
  #
  # @[ADI::Register(public: true)]
  # record FloatArr, value_arr : Array(Float64)
  #
  # @[ADI::Register(public: true)]
  # record BoolArr, value_arr : Array(Bool)
  #
  # ADI.container.binding_client # =>
  # # BindingClient(
  # #  @api_key="123ABC",
  # #  @config={id: 12, active: true},
  # #  @static_value=123,
  # #  @odd_values=[ValueService(@value=1), ValueService(@value=3)])
  #
  # ADI.container.int_arr   # => IntArr(@value_arr=[1, 2, 3])
  # ADI.container.float_arr # => FloatArr(@value_arr=[1.0, 2.0, 3.0])
  # ADI.container.bool_arr  # => BoolArr(@value_arr=[true, true, false])
  # ```
  macro bind(key, value)
    {% if key.is_a? TypeDeclaration %}
      {% name = key.var.id.stringify %}
      {% type = key.type.resolve %}
    {% else %}
      {% name = key.id.stringify %}
      {% type = Crystal::Macros::Nop %}
    {% end %}

    # TODO: Refactor this to ||= once https://github.com/crystal-lang/crystal/pull/9409 is released
    {% BINDINGS[name] = {typed: [] of Nil, untyped: [] of Nil} if BINDINGS[name] == nil %}

    {% if type == Crystal::Macros::Nop %}
      {% BINDINGS[name][:untyped].unshift({value: value, type: type}) %}
    {% else %}
      {% BINDINGS[name][:typed].unshift({value: value, type: type}) %}
    {% end %}
  end

  # Registers a service based on the type the annotation is applied to.
  #
  # The type of the service affects how it behaves within the container.  When a `struct` service is retrieved or injected into a type, it will be a copy of the one in the SC (passed by value).
  # This means that changes made to it in one type, will _NOT_ be reflected in other types.  A `class` service on the other hand will be a reference to the one in the SC.  This allows it
  # to share state between services.
  #
  # ## Optional Arguments
  #
  # In most cases, the annotation can be applied without additional arguments.  However, the annotation accepts a handful of optional arguments to fine tune how the service is registered.
  #
  # * `name : String`- The name of the service.  Should be unique.  Defaults to the type's FQN snake cased.
  # * `public : Bool` - If the service should be directly accessible from the container.  Defaults to `false`.
  # * `public_alias : Bool` - If a service should be directly accessible from the container via an alias.  Defaults to `false`.
  # * `alias : T` - Injects `self` when this type is used as a type restriction.  See the Aliasing Services example for more information.
  # * `tags : Array(String | NamedTuple(name: String, priority: Int32?))` - Tags that should be assigned to the service.  Defaults to an empty array.  See the [Tagging Services][Athena::DependencyInjection::Register--tagging-services] example for more information.
  # * `type : T` - The type of the service within the container.  Defaults to service's types.  See the [Customizing Service's Type](#customizing-services-type) section.
  # * `factory : String | Tuple(T, String)` - Use a factory type/method to create the service.  See the [Factories](#factories) section.
  #
  # ## Examples
  #
  # ### Basic Usage
  #
  # The simplest usage involves only applying the `ADI::Register` annotation to a type.  If the type does not have any arguments, then it is simply registered as a service as is.  If the type _does_ have arguments, then an attempt is made to register the service by automatically resolving dependencies based on type restrictions.
  #
  # ```
  # @[ADI::Register]
  # # Register a service without any dependencies.
  # struct ShoutTransformer
  #   def transform(value : String) : String
  #     value.upcase
  #   end
  # end
  #
  # @[ADI::Register(public: true)]
  # # The ShoutTransformer is injected based on the type restriction of the `transformer` argument.
  # struct SomeAPIClient
  #   def initialize(@transformer : ShoutTransformer); end
  #
  #   def send(message : String)
  #     message = @transformer.transform message
  #
  #     # ...
  #   end
  # end
  #
  # ADI.container.some_api_client.send "foo" # => FOO
  # ```
  #
  # ### Aliasing Services
  #
  # An important part of DI is building against interfaces as opposed to concrete types.  This allows a type to depend upon abstractions rather than a specific implementation of the interface.
  # Or in other words, prevents a singular implementation from being tightly coupled with another type.
  #
  # We can use the `alias` argument when registering a service to tell the container that it should inject this service when a type restriction for the aliased service is found.
  #
  # ```
  # # Define an interface for our services to use.
  # module TransformerInterface
  #   abstract def transform(value : String) : String
  # end
  #
  # @[ADI::Register(alias: TransformerInterface)]
  # # Alias the `TransformerInterface` to this service.
  # struct ShoutTransformer
  #   include TransformerInterface
  #
  #   def transform(value : String) : String
  #     value.upcase
  #   end
  # end
  #
  # @[ADI::Register]
  # # Define another transformer type.
  # struct ReverseTransformer
  #   include TransformerInterface
  #
  #   def transform(value : String) : String
  #     value.reverse
  #   end
  # end
  #
  # @[ADI::Register(public: true)]
  # # The `ShoutTransformer` is injected because the `TransformerInterface` is aliased to the `ShoutTransformer`.
  # struct SomeAPIClient
  #   def initialize(@transformer : TransformerInterface); end
  #
  #   def send(message : String)
  #     message = @transformer.transform message
  #
  #     # ...
  #   end
  # end
  #
  # ADI.container.some_api_client.send "foo" # => FOO
  # ```
  #
  # Any service that uses `TransformerInterface` as a dependency type restriction will get the `ShoutTransformer`.
  # However, it is also possible to use a specific implementation while still building against the interface.  The name of the constructor argument is used in part to resolve the dependency.
  #
  # ```
  # @[ADI::Register(public: true)]
  # # The `ReverseTransformer` is injected because the constructor argument's name matches the service name of `ReverseTransformer`.
  # struct SomeAPIClient
  #   def initialize(reverse_transformer : TransformerInterface)
  #     @transformer = reverse_transformer
  #   end
  #
  #   def send(message : String)
  #     message = @transformer.transform message
  #
  #     # ...
  #   end
  # end
  #
  # ADI.container.some_api_client.send "foo" # => oof
  # ```
  #
  # ### Scalar Arguments
  #
  # The auto registration logic as shown in previous examples only works on service dependencies.  Scalar arguments, such as Arrays, Strings, NamedTuples, etc, must be defined manually.
  # This is achieved by using the argument's name prefixed with a `_` symbol as named arguments within the annotation.
  #
  # ```
  # @[ADI::Register(_shell: ENV["SHELL"], _config: {id: 12_i64, active: true}, public: true)]
  # struct ScalarClient
  #   def initialize(@shell : String, @config : NamedTuple(id: Int64, active: Bool)); end
  # end
  #
  # ADI.container.scalar_client # => ScalarClient(@config={id: 12, active: true}, @shell="/bin/bash")
  # ```
  # Arrays can also include references to services by prefixing the name of the service with an `@` symbol.
  #
  # ```
  # module Interface; end
  #
  # @[ADI::Register]
  # struct One
  #   include Interface
  # end
  #
  # @[ADI::Register]
  # struct Two
  #   include Interface
  # end
  #
  # @[ADI::Register]
  # struct Three
  #   include Interface
  # end
  #
  # @[ADI::Register(_services: ["@one", "@three"], public: true)]
  # struct ArrayClient
  #   def initialize(@services : Array(Interface)); end
  # end
  #
  # ADI.container.array_client # => ArrayClient(@services=[One(), Three()])
  # ```
  #
  # While scalar arguments cannot be auto registered by default, the `Athena::DependencyInjection.bind` macro can be used to support it.  For example: `ADI.bind shell, "bash"`.
  # This would now inject the string `"bash"` whenever an argument named `shell` is encountered.
  #
  # ### Tagging Services
  #
  # Services can also be tagged.  Service tags allows another service to have all services with a specific tag injected as a dependency.
  # A tag consists of a name, and additional metadata related to the tag.
  # Currently the only supported metadata value is `priority`, which controls the order in which the services are injected; the higher the priority
  # the sooner in the array it would be.  In the future support for custom tag metadata will be implemented.
  #
  # The `Athena::DependencyInjection.auto_configure` macro may also be used to make working with tags easier.
  #
  # ```
  # PARTNER_TAG = "partner"
  #
  # @[ADI::Register(_id: 1, name: "google", tags: [{name: PARTNER_TAG, priority: 5}])]
  # @[ADI::Register(_id: 2, name: "facebook", tags: [PARTNER_TAG])]
  # @[ADI::Register(_id: 3, name: "yahoo", tags: [{name: "partner", priority: 10}])]
  # @[ADI::Register(_id: 4, name: "microsoft", tags: [PARTNER_TAG])]
  # # Register multiple services based on the same type.  Each service must give define a unique name.
  # record FeedPartner, id : Int32
  #
  # @[ADI::Register(_services: "!partner", public: true)]
  # # Inject all services with the `"partner"` tag into `self`.
  # class PartnerClient
  #   def initialize(@services : Array(FeedPartner)); end
  # end
  #
  # ADI.container.partner_client # =>
  # # #<PartnerClient:0x7f43c0a1ae60
  # #  @services=
  # #   [FeedPartner(@id=3, @name="Yahoo"),
  # #    FeedPartner(@id=1, @name="Google"),
  # #    FeedPartner(@id=2, @name="Facebook"),
  # #    FeedPartner(@id=4, @name="Microsoft")]>
  # ```
  #
  # While tagged services cannot be injected automatically by default, the `Athena::DependencyInjection.bind` macro can be used to support it.  For example: `ADI.bind partners, "!partner"`.
  # This would now inject all services with the `partner` tagged when an argument named `partners` is encountered.
  # A type restriction can also be added to the binding to allow reusing the name.  See the documentation for `Athena::DependencyInjection.bind` for an example.
  #
  # ### Service Proxies
  #
  # In some cases, it may be a bit "heavy" to instantiate a service that may only be used occasionally.
  # To solve this, a proxy of the service could be injected instead.
  # The instantiation of proxied services are deferred until a method is called on it.
  #
  # A service is proxied by changing the type signature of the service to be of the `ADI::Proxy(T)` type, where `T` is the service to be proxied.
  #
  # ```
  # @[ADI::Register]
  # class ServiceTwo
  #   getter value = 123
  #
  #   def initialize
  #     pp "new s2"
  #   end
  # end
  #
  # @[ADI::Register(public: true)]
  # class ServiceOne
  #   getter service_two : ADI::Proxy(ServiceTwo)
  #
  #   # Tells `ADI` that a proxy of `ServiceTwo` should be injected.
  #   def initialize(@service_two : ADI::Proxy(ServiceTwo))
  #     pp "new s1"
  #   end
  #
  #   def run
  #     # At this point service_two hasn't been initialized yet.
  #     pp "before value"
  #
  #     # First method interaction with the proxy instantiates the service and forwards the method to it.
  #     pp @service_two.value
  #   end
  # end
  #
  # ADI.container.service_one.run
  # # "new s1"
  # # "before value"
  # # "new s2"
  # # 123
  # ```
  #
  # #### Tagged Services Proxies
  #
  # Tagged services may also be injected as an array of proxy objects.
  # This can be useful as an easy way to manage a collection of services where only one (or a small amount) will be used at a time.
  #
  # ```
  # @[ADI::Register(_services: "!some_tag")]
  # class SomeService
  #   def initialize(@services : Array(ADI::Proxy(ServiceType)))
  #   end
  # end
  # ```
  #
  # #### Proxy Metadata
  #
  # The `ADI::Proxy` object also exposes some metadata related to the proxied object; such as its name, type, and if it has been instantiated yet.
  #
  # For example, using `ServiceTwo`:
  #
  # ```
  # # Assume this returns a `ADI::Proxy(ServiceTwo)`.
  # proxy = ADI.container.service_two
  #
  # proxy.service_id    # => "service_two"
  # proxy.service_type  # => ServiceTwo
  # proxy.instantiated? # => false
  # proxy.value         # => 123
  # proxy.instantiated? # => true
  # ```
  #
  # ### Parameters
  #
  # The `Athena::Config` component provides a way to manage `ACF::Parameters` objects used to define reusable [parameters](/components/config#parameters).
  # It is possible to inject these parameters directly into services in a type safe way.
  #
  # Parameter injection utilizes a specially formatted string, similar to tagged services.
  # The parameter name should be a string starting and ending with a `%`, e.g. `"%app.database.username%"`.
  # The value within the `%` represents the "path" to the parameter from the `ACF::Parameters` base type.
  #
  # Parameters may be supplied either via `Athena::DependencyInjection.bind` or an explicit service argument.
  #
  # ```
  # struct DatabaseConfig
  #   getter username : String = "USERNAME"
  # end
  #
  # struct AppConfig
  #   getter name : String = "My App"
  #   getter database : DatabaseConfig = DatabaseConfig.new
  # end
  #
  # class Athena::Config::Parameters
  #   getter app : AppConfig = AppConfig.new
  # end
  #
  # ADI.bind db_username, "%app.database.username%"
  #
  # @[ADI::Register(_app_name: "%app.name%", public: true)]
  # record SomeService, app_name : String, db_username : String
  #
  # service = ADI.container.some_service
  # service.app_name    # => "My App"
  # service.db_username # => "USERNAME"
  # ```
  #
  # ### Configuration
  #
  # The `Athena::Config` component provides a way to manage `ACF::Base` objects used for [configuration](/components/config#configuration).
  # The `Athena::DependencyInjection` component leverages the `ACFA::Resolvable` annotation to allow injecting entire configuration objects into services
  # in addition to individual [parameters][Athena::DependencyInjection::Register--parameters].
  #
  # The primary use case for is for types that have functionality that should be configurable by the end user.
  # The configuration object could be injected as a constructor argument to set the value of instance variables, or be one itself.
  #
  # ```
  # # Define an example configuration type for a fictional Athena component.
  # # The annotation argument describes the "path" to this particular configuration
  # # type from `ACF.config`. I.e. `ACF.config.some_component`.
  # @[ACFA::Resolvable("some_component")]
  # struct SomeComponentConfig
  #   # By default return a new instance with a default value.
  #   def self.configure : self
  #     new
  #   end
  #
  #   getter multiplier : Int32
  #
  #   def initialize(@multiplier : Int32 = 1); end
  # end
  #
  # # This type would be a part of the `ACF::Base` type.
  # class ACF::Base
  #   getter some_component : SomeComponentConfig = SomeComponentConfig.configure
  # end
  #
  # # Define an example configurable service to use our configuration object.
  # @[ADI::Register(public: true)]
  # class MultiplierService
  #   @multiplier : Int32
  #
  #   def initialize(config : SomeComponentConfig)
  #     @multiplier = config.multiplier
  #   end
  #
  #   def multiply(value : Number)
  #     value * @multiplier
  #   end
  # end
  #
  # ADI.container.multiplier_service.multiply 10 # => 10
  # ```
  #
  # By default our `MultiplierService` will use a multiplier of `1`, the default value in the `SomeComponentConfig`.
  # However, if we wanted to change that value we could do something like this, without changing any of the earlier code.
  #
  # ```
  # # Override the configuration type's configure method
  # # to supply our own custom multiplier value.
  # def SomeComponentConfig.configure
  #   new 10
  # end
  #
  # ADI.container.multiplier_service.multiply 10 # => 100
  # ```
  #
  # If the configurable service is also used outside of the service container,
  # the [factory][Athena::DependencyInjection::Register--factories] pattern could also be used.
  #
  # ```
  # @[ADI::Register(public: true)]
  # class MultiplierService
  #   # Tell the service container to use this constructor for DI.
  #   @[ADI::Inject]
  #   def self.new(config : SomeComponentConfig)
  #     # Using the configuration object to supply the argument to the standard initialize method.
  #     new config.multiplier
  #   end
  #
  #   def initialize(@multiplier : Int32); end
  #
  #   def multiply(value : Number)
  #     value * @multiplier
  #   end
  # end
  #
  # # Multiplier from the service container.
  # ADI.container.multiplier_service.multiply 10 # => 10
  #
  # # A directly instantiated type.
  # MultiplierService.new(10).multiply 10 # => 100
  # ```
  #
  # ### Optional Services
  #
  # Services defined with a nillable type restriction are considered to be optional.  If no service could be resolved from the type, then `nil` is injected instead.
  # Similarly, if the argument has a default value, that value would be used instead.
  #
  # ```
  # struct OptionalMissingService
  # end
  #
  # @[ADI::Register]
  # struct OptionalExistingService
  # end
  #
  # @[ADI::Register(public: true)]
  # class OptionalClient
  #   getter service_missing, service_existing, service_default
  #
  #   def initialize(
  #     @service_missing : OptionalMissingService?,
  #     @service_existing : OptionalExistingService?,
  #     @service_default : OptionalMissingService | Int32 | Nil = 12
  #   ); end
  # end
  #
  # ADI.container.optional_client
  # # #<OptionalClient:0x7fe7de7cdf40
  # #  @service_default=12,
  # #  @service_existing=OptionalExistingService(),
  # #  @service_missing=nil>
  # ```
  #
  # ### Generic Services
  #
  # Generic arguments can be provided as positional arguments within the `ADI::Register` annotation.
  #
  # !!!note
  #     Services based on generic types _MUST_ explicitly provide a name via the `name` field within the `ADI::Register` annotation
  #     since there wouldn't be a way to tell them apart from the class name alone.
  #
  # ```
  # @[ADI::Register(Int32, Bool, name: "int_service", public: true)]
  # @[ADI::Register(Float64, Bool, name: "float_service", public: true)]
  # struct GenericService(T, B)
  #   def type
  #     {T, B}
  #   end
  # end
  #
  # ADI.container.int_service.type   # => {Int32, Bool}
  # ADI.container.float_service.type # => {Float64, Bool}
  # ```
  #
  # ### Factories
  #
  # In some cases it may be necessary to use the [factory design pattern](https://en.wikipedia.org/wiki/Factory_%28object-oriented_programming%29)
  # to handle creating an object as opposed to creating the object directly.  In this case the `factory` argument can be used.
  #
  # Factory methods are class methods defined on some type; either the service itself or a different type.
  # Arguments to the factory method are provided as they would if the service was being created directly.
  # This includes auto resolved service dependencies, and scalar underscore based arguments included within the `ADI::Register` annotation.
  #
  # #### Same Type
  #
  # A `String` `factory` value denotes the method name that should be called on the service itself to create the service.
  #
  # ```
  # # Calls `StringFactoryService.double` to create the service.
  # @[ADI::Register(_value: 10, public: true, factory: "double")]
  # class StringFactoryService
  #   getter value : Int32
  #
  #   def self.double(value : Int32) : self
  #     new value * 2
  #   end
  #
  #   def initialize(@value : Int32); end
  # end
  #
  # ADI.container.string_factory_service.value # => 20
  # ```
  #
  # Using the `ADI::Inject` annotation on a class method is equivalent to providing that method's name as the `factory` value.
  # For example, this is the same as the previous example:
  #
  # ```
  # @[ADI::Register(_value: 10, public: true)]
  # class StringFactoryService
  #   getter value : Int32
  #
  #   @[ADI::Inject]
  #   def self.double(value : Int32) : self
  #     new value * 2
  #   end
  #
  #   def initialize(@value : Int32); end
  # end
  #
  # ADI.container.string_factory_service.value # => 20
  # ```
  #
  # #### Different Type
  #
  # A `Tuple` can also be provided as the `factory` value to allow using an external type's factory method to create the service.
  # The first item represents the factory type to use, and the second item represents the method that should be called.
  #
  # ```
  # class TestFactory
  #   def self.create_tuple_service(value : Int32) : TupleFactoryService
  #     TupleFactoryService.new value * 3
  #   end
  # end
  #
  # # Calls `TestFactory.create_tuple_service` to create the service.
  # @[ADI::Register(_value: 10, public: true, factory: {TestFactory, "create_tuple_service"})]
  # class TupleFactoryService
  #   getter value : Int32
  #
  #   def initialize(@value : Int32); end
  # end
  #
  # ADI.container.tuple_factory_service.value # => 30
  # ```
  #
  # ### Customizing Service's Type
  #
  # By default when a service is registered, it is typed the same as the service, for example:
  #
  # ```
  # @[ADI::Register]
  # class MyService; end
  # ```
  #
  # This service is essentially represented in the service container as `@my_service : MyService`.
  # This is usually fine for most services, however there are some cases where the service's type should not be the concrete implementation.
  # An example of this is if that service should be mockable in a test setting.  Mockable services should be typed to an interface that they implement
  # in order to allow mock implementations to be used if needed.
  #
  # ```
  # module SomeInterface; end
  #
  # @[ADI::Register(type: SomeInterface)]
  # class MyService
  #   include SomeInterface
  # end
  # ```
  #
  # By specifying the `type` as `SomeInterface`, this changes the services representation in the service container to `@my_service : SomeInterface`,
  # thus allowing the exact implementation to be changed.  See `ADI::Spec::MockableServiceContainer` for more details.
  annotation Register; end

  # Specifies which constructor should be used for injection.
  #
  # ```
  # @[ADI::Register(_value: 2, public: true)]
  # class SomeService
  #   @active : Bool = false
  #
  #   def initialize(value : String, @active : Bool)
  #     @value = value.to_i
  #   end
  #
  #   @[ADI::Inject]
  #   def initialize(@value : Int32); end
  # end
  #
  # ADI.container.some_service # => #<SomeService:0x7f51a77b1eb0 @active=false, @value=2>
  # SomeService.new "1", true  # => #<SomeService:0x7f51a77b1e90 @active=true, @value=1>
  # ```
  #
  # Without the `ADI::Inject` annotation, the first initializer would be used, which would fail since we are not providing a value for the `active` argument.
  # `ADI::Inject` allows telling the service container that it should use the second constructor when registering this service.  This allows a constructor overload
  # specific to DI to be used while still allowing the type to be used outside of DI via other constructors.
  #
  # Using the `ADI::Inject` annotation on a class method also acts a shortcut for defining a service [factory][Athena::DependencyInjection::Register--factories].
  annotation Inject; end

  # Returns the `ADI::ServiceContainer` for the current fiber.
  def self.container : ADI::ServiceContainer
    Fiber.current.container
  end
end
