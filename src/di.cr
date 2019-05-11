require "./di/service_container"
require "./di/definition"

# :nodoc:
class Fiber
  property! container : Athena::DI::ServiceContainer
end

module Athena::DI
  annotation Register; end

  # :nodoc:
  abstract struct Service; end

  # The container instance.
  class_getter container : Athena::DI::ServiceContainer = Athena::DI::ServiceContainer.new

  # Returns the container
  def self.get_container : Athena::DI::ServiceContainer
    Fiber.current.container
  end

  # Adds a new initializer that injects the required objects.
  module Injectable
    macro included
      macro finished
        \{% for method in @type.methods.select { |m| m.name == "initialize" } %}
          def self.new(**args)
            new(
              \{% for arg in method.args %}
                \{{arg.name.id}}: args[:\{{arg.name.id}}]? || Athena::DI.get_container.resolve(\{{arg.restriction.id}}, \{{arg.name.stringify}}),
              \{% end %}
            )
          end
        \{% end %}
      end
    end
  end
end

Fiber.current.container = Athena::DI.container
