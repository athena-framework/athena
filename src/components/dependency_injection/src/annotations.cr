module Athena::DependencyInjection
  # Allows defining an alternative name to identify a service.
  # This helps solve two primary use cases:
  #
  # 1. Defining a default service to use when a parameter is typed as an interface
  # 1. Decoupling a service from its ID to more easily allow customizing it.
  #
  # ### Default Service
  #
  # This annotation may be applied to a service that includes one or more interface(s).
  # The annotation can then be provided the interface to alias as the first positional argument.
  # If the service only includes one interface (module ending with `Interface`), the annotation argument can be omitted.
  # Multiple annotations may be applied if it includes more than one.
  #
  # ```
  # module SomeInterface; end
  #
  # module OtherInterface; end
  #
  # module BlahInterface; end
  #
  # # `Foo` is implicitly aliased to `SomeInterface` since it only includes the one.
  # @[ADI::Register]
  # @[ADI::AsAlias] # SomeInterface is assumed
  # class Foo
  #   include SomeInterface
  # end
  #
  # # Alias `Bar` to both included interfaces.
  # @[ADI::Register]
  # @[ADI::AsAlias(BlahInterface)]
  # @[ADI::AsAlias(OtherInterface)]
  # class Bar
  #   include BlahInterface
  #   include OtherInterface
  # end
  # ```
  #
  # In this example, anytime a parameter restriction for `SomeInterface` is encountered, `Foo` will be injected.
  # Similarly, anytime a parameter restriction of `BlahInterface` or `OtherInterface` is encountered, `Bar` will be injected.
  # This can be especially useful for when you want to define a default service to use when there are multiple implementations of an interface.
  #
  # ### String Keys
  #
  # The use case for string keys is you can do something like this:
  #
  # ```
  # @[ADI::Register(name: "default_service")]
  # @[ADI::AsAlias("my_service")]
  # class SomeService
  # end
  # ```
  # The idea being, have a service with an internal `default_service` id, but alias it to a more general `my_service` id.
  # Dependencies could then be wired up to depend upon the `"@my_service"` implementation.
  # This enabled the user/other logic to override the `my_service` alias to their own implementation (assuming it implements same API/interface(s)).
  # This should allow everything to propagate and use the custom type without having to touch the original `default_service`.
  annotation AsAlias; end

  # Applies the provided configuration to any registered service of the type the annotation is applied to.
  # E.g. a module interface, or a parent type.
  #
  # The following values may be auto-configured:
  #
  # * `tags : Array(String | NamedTuple(name: String, priority: Int32?))` - The [tags](/DependencyInjection/Register/#Athena::DependencyInjection::Register--tagging-services) to apply.
  # * `calls : Array(Tuple(String, Tuple(T)))` - [Service calls](/DependencyInjection/Register/#Athena::DependencyInjection::Register--service-calls) that should be made on the service after its instantiated.
  # * `bind : NamedTuple(*)` - A named tuple of values that should be available to the constructors
  # * `public : Bool` - If the services should be accessible directly from the container
  # * `constructor : String` - Name of a class method to use as the [service factory](/DependencyInjection/Register/#Athena::DependencyInjection::Register--factories)
  #
  # TIP: Checkout `ADI::AutoconfigureTag` and `ADI::TaggedIterator` for a simpler way of handling tags.
  #
  # ### Example
  #
  # ```
  # @[ADI::Autoconfigure(bind: {id: 123}, public: true)]
  # module SomeInterface; end
  #
  # @[ADI::Register]
  # record One do
  #   include SomeInterface
  # end
  #
  # @[ADI::Register]
  # record Two, id : Int32 do
  #   include SomeInterface
  # end
  #
  # # The services are only accessible like this since they were auto-configured to be public.
  # ADI.container.one # => One()
  #
  # # `123` is used as it was bound to all services that include `SomeInterface`.
  # ADI.container.two # => Two(@id=123)
  # ```
  annotation Autoconfigure; end

  # Similar to `ADI::Autoconfigure` but specialized for easily configuring [tags](/DependencyInjection/Register/#Athena::DependencyInjection::Register--tagging-services).
  # Accepts an optional tag name as the first positional parameter, otherwise defaults to the FQN of the type.
  # Named arguments may also be provided that'll be added to the tag as attributes.
  #
  # TIP: This type is best used in conjunction with `ADI::TaggedIterator`.
  #
  # ### Example
  #
  # ```
  # # All services including `SomeInterface` will be tagged with `"some-tag"`.
  # @[ADI::AutoconfigureTag("some-tag")]
  # module SomeInterface; end
  #
  # # All services including `OtherInterface` will be tagged with `"OtherInterface"`.
  # @[ADI::AutoconfigureTag]
  # module OtherInterface; end
  # ```
  annotation AutoconfigureTag; end

  # Can be applied to a collection parameter to provide all the services with a specific tag.
  # Supported collection types include: `Indexable`, `Enumerable`, and `Iterator`.
  # Accepts an optional tag name as the first positional parameter, otherwise defaults to the FQN of the type within the collection type's generic.
  #
  # TIP: This type is best used in conjunction with `ADI::AutoconfigureTag`.
  #
  # The provided type lazily initializes the provided services as they are accessed.
  #
  # ### Example
  #
  # ```
  # @[ADI::Register]
  # class Foo
  #   # Inject all services tagged with `"some-tag"`.
  #   def initialize(@[ADI::TaggedIterator("some-tag")] @services : Enumerable(SomeInterface)); end
  # end
  #
  # @[ADI::Register]
  # class Bar
  #   # Inject all services tagged with `"SomeInterface"`.
  #   def initialize(@[ADI::TaggedIterator] @services : Enumerable(SomeInterface)); end
  # end
  # ```
  annotation TaggedIterator; end

  # Automatically registers a service based on the type the annotation is applied to.
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
  # * `factory : String | Tuple(T, String)` - Use a factory type/method to create the service.  See the [Factories](#factories) section.
  # * `public : Bool` - If the service should be directly accessible from the container.  Defaults to `false`.
  # * `alias : Array(T)` - Injects `self` when any of these types are used as a type restriction.  See the Aliasing Services example for more information.
  # * `tags : Array(String | NamedTuple(name: String, priority: Int32?))` - Tags that should be assigned to the service.  Defaults to an empty array.  See the [Tagging Services][Athena::DependencyInjection::Register--tagging-services] example for more information.
  # * `calls : Array(Tuple(String, Tuple(T)))` - Calls that should be made on the service after its instantiated.
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
  # An important part of DI is building against interfaces as opposed to concrete types.
  # This allows a type to depend upon abstractions rather than a specific implementation of the interface.
  # Or in other words, prevents a singular implementation from being tightly coupled with another type.
  #
  # The `ADI::AsAlias` annotation can be used to define a default implementation for an interface.
  # Checkout the annotation's docs for more information.
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
  # Services can also be tagged.
  # Service tags allows another service to have all services with a specific tag injected as a dependency.
  # A tag consists of a name, and additional metadata related to the tag.
  #
  # TIP: Checkout `ADI::AutoconfigureTag` for an easy way to tag services.
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
  # @[ADI::Register(public: true)]
  # class PartnerClient
  #   getter services : Enumerable(FeedPartner)
  #
  #   def initialize(@[ADI::TaggedIterator(PARTNER_TAG)] @services : Enumerable(FeedPartner)); end
  # end
  #
  # ADI.container.partner_client.services.to_a # =>
  # # [FeedPartner(@id=3),
  # #  FeedPartner(@id=1),
  # #  FeedPartner(@id=2),
  # #  FeedPartner(@id=4)]
  # ```
  #
  # The `ADI::TaggedIterator` annotation provides an easy way to inject services with a specific tag to a specific parameter.
  #
  # ### Service Calls
  #
  # Service calls can be defined that will call a specific method on the service, with a set of arguments.
  # Use cases for this are generally not all that common, but can sometimes be useful.
  #
  # ```
  # @[ADI::Register(public: true, calls: [
  #   {"foo"},
  #   {"foo", {3}},
  #   {"foo", {6}},
  # ])]
  # class CallClient
  #   getter values = [] of Int32
  #
  #   def foo(value : Int32 = 1)
  #     @values << value
  #   end
  # end
  #
  # ADI.container.call_client.values # => [1, 3, 6]
  # ```
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
  # Reusable configuration [parameters](/getting_started/configuration#parameters) can be injected directly into services using the same syntax as when used within `ADI.configure`.
  # Parameters may be supplied either via `Athena::DependencyInjection.bind` or an explicit service argument.
  #
  # ```
  # ADI.configure({
  #   parameters: {
  #     "app.name":              "My App",
  #     "app.database.username": "administrator",
  #   },
  # })
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
  #     @service_default : OptionalMissingService | Int32 | Nil = 12,
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

  # :nodoc:
  annotation Bundle; end
end
