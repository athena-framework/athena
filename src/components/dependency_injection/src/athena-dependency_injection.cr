require "./annotations"
require "./annotation_configurations"
require "./extension"
require "./proxy"
require "./service_container"

# :nodoc:
class Fiber
  property container : ADI::ServiceContainer { ADI::ServiceContainer.new }
end

# Convenience alias to make referencing `Athena::DependencyInjection` types easier.
alias ADI = Athena::DependencyInjection

# Robust dependency injection service container framework.
module Athena::DependencyInjection
  VERSION = "0.3.8"

  private BINDINGS   = {} of Nil => Nil
  private EXTENSIONS = {} of Nil => Nil

  # :nodoc:
  CONFIG = {parameters: {__nil: nil}} # Ensure this type is a NamedTupleLiteral

  private CONFIGS = [] of Nil

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
    {% BINDINGS[key] = value %}
  end

  # Returns the `ADI::ServiceContainer` for the current fiber.
  def self.container : ADI::ServiceContainer
    Fiber.current.container
  end

  # Namespace for DI extension related types.
  module Extension; end

  # Primary entrypoint for configuring `ADI::Extension::Schema`s.
  macro configure(config)
    {%
      CONFIGS << config
    %}
  end

  # Adds a compiler *pass*, optionally of a specific *type* and *priority* (default `0`).
  #
  # Valid types include:
  #
  # * `:before_optimization` (default)
  # * `:optimization`
  # * `:before_removing`
  # * `:after_removing`
  # * `:removing`
  #
  # EXPERIMENTAL: This feature is intended for internal/advanced use and, for now, comes with limited public documentation.
  macro add_compiler_pass(pass, type = nil, priority = nil)
    {%
      pass_type = pass.resolve

      pass.raise "Pass type must be a module." unless pass_type.module?

      type = type || :before_optimization
      priority = priority || 0

      if hash = ADI::ServiceContainer::PASS_CONFIG[type]
        hash[priority] = [] of Nil if hash[priority] == nil

        hash[priority] << pass_type.id
      else
        type.raise "Invalid compiler pass type: '#{type}'."
      end
    %}
  end

  # Registers an extension `ADI::Extension::Schema` with the provided *name*.
  macro register_extension(name, schema)
    {% ADI::ServiceContainer::EXTENSIONS[name.id.stringify] = schema %}
  end

  # :nodoc:
  macro service_iterator(for name, services)
    {% begin %}
      private struct {{name.camelcase.id}}(T, S)
        include Iterator(T)
        include Indexable(T)

        @offset = 0

        def initialize(@container : ADI::ServiceContainer); end

        def next : T | Iterator::Stop
          return stop if @offset == S

          self
            .unsafe_fetch(@offset)
            .tap { @offset += 1 }
        end

        def size : Int32
          S
        end

        def rewind : Nil
          @offset = 0
        end

        # :nodoc:
        def unsafe_fetch(index : Int) : T
          case index
            {% for service_id, idx in services %}
              when {{idx}} then @container.{{service_id.id}}\
            {% end %}
          else
            raise ""
          end
        end
      end
    {% end %}
  end
end
