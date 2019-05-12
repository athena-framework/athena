require "./dependency_injection/service_container"
require "./dependency_injection/definition"

# :nodoc:
class Fiber
  property! container : Athena::DI::ServiceContainer
end

# Dependency Injection module
#
# * Adds a service container layer
# * Auto injection
# * Auto registration
# * Fiber specific contexts
module Athena::DI
  # Tells `Athena::DI` that this type should be auto registered.
  #
  # ## Fields
  # * name : `String`- The name that should be used for the service.  Defaults to the type name snake cased.
  # * tags : `Array(String)` - Tags that should be assigned to the service.
  #
  # ## Example
  #
  # With no initializer.
  # ```
  # @[Athena::DI::Register]
  # class Store < Athena::DI::Service
  #   property uuid : String? = nil
  # end
  # ```
  #
  # Registering multiple services of the same class with an initializer.
  # ```
  # @[Athena::DI::Register("GOOGLE", "Google", name: "google")]
  # @[Athena::DI::Register("FACEBOOK", "Facebook", name: "facebook")]
  # struct FeedPartner < Athena::DI::Service
  #   getter id : String
  #   getter name : String
  #
  #   def initialize(@id : String, @name : String); end
  # end
  # ```
  annotation Register; end

  # :nodoc:
  module Service
  end

  # Parent struct of services that will inject a new instance.
  abstract struct StructService
    include Service
  end

  # Parent class of services that will inject the same instance.
  abstract class ClassService
    include Service
  end

  # The container that all objects live in.
  class_getter container : Athena::DI::ServiceContainer = Athena::DI::ServiceContainer.new

  # Returns the container for the current fiber.
  #
  # NOTE: By default this is the main fiber, the container would have to be set manually within each child fiber.
  def self.get_container : Athena::DI::ServiceContainer
    Fiber.current.container
  end

  # Adds a new initializer that injects the required objects based on type and name.
  module Injectable
    macro included
      macro finished
        \{% for method in @type.methods.select { |m| m.name == "initialize" } %}
          def self.new(**args)
            new(
              \{% for arg in method.args %}
                \{{arg.name.id}}: args[\{{arg.name.symbolize}}]? || Athena::DI.get_container.resolve(\{{arg.restriction.id}}, \{{arg.name.stringify}}),
              \{% end %}
            )
          end
        \{% end %}
      end
    end
  end
end

# Set the container on the current (main) fiber so its available project wide from start.
Fiber.current.container = Athena::DI.container
