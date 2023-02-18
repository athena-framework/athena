require "./annotations"
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
#
# ## Getting Started
#
# If using this component within the [Athena Framework][Athena::Framework], it is already installed and required for you.
# Checkout the [manual](/architecture/dependency_injection) for some additional information on how to use it within the framework.
#
# If using it outside of the framework, you will first need to add it as a dependency:
#
# ```yaml
# dependencies:
#   athena-dependency_injection:
#     github: athena-framework/dependency-injection
#     version: ~> 0.3.0
# ```
#
# Then run `shards install`, being sure to require it via `require "athena-dependency_injection"`.
#
# From here integration of the component depends on the execution flow of your application, and how it uses [Fibers](https://crystal-lang.org/api/Fiber.html).
# Since each fiber has its own container instance, if your application only uses Crystal's main fiber and is short lived, then you most likely only need to set up your services
# and expose one of them as [public][Athena::DependencyInjection::Register--optional-arguments] to serve as the entry point.
#
# If your application is meant to be long lived, such as using a [HTTP::Server](https://crystal-lang.org/api/HTTP/Server.html), then you will want to ensure that each
# fiber is truly independent from one another, with them not being reused or sharing state external to the container. An example of this is how `HTTP::Server` reuses fibers
# for `connection: keep-alive` requests. Because of this, or in cases similar to, you may want to manually reset the container via `Fiber.current.container = ADI::ServiceContainer.new`.
module Athena::DependencyInjection
  VERSION = "0.3.6"

  private BINDINGS            = {} of Nil => Nil
  private AUTO_CONFIGURATIONS = {} of Nil => Nil

  # :nodoc:
  module PreArgumentsCompilerPass; end

  # :nodoc:
  module PostArgumentsCompilerPass; end

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

  # Returns the `ADI::ServiceContainer` for the current fiber.
  def self.container : ADI::ServiceContainer
    Fiber.current.container
  end
end

# Require extension code last so all built-in DI types are available
require "./ext/*"
