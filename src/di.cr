require "./dependency_injection/service_container"

# :nodoc:
class Fiber
  property container : Athena::DI::ServiceContainer { Athena::DI::ServiceContainer.new }
end

# Convenience alias to make referencing `Athena::DI` types easier.
alias ADI = Athena::DI

# Athena's Dependency Injection (DI) component adds a service container layer to your project.  This allows a project to share useful objects, aka services, throughout the project.
# These objects live in a special struct called the `Athena::DI::ServiceContainer` (SC).  Object instances can be retrieved from the container, or even injected directly into types as a form of constructor DI.
#
# The SC is lazily initialized on fibers; this allows the SC to be accessed anywhere within the project.  The `Athena::DI.container` method will return the SC for the current fiber.
# Since the SC is defined on fibers, it allows for each fiber to have its own SC.  This can be useful for web frameworks as each request would have its own SC scoped to that request.
# This however, is up to the each project to implement.
#
# * See `ADI::Register` for documentation on registering services.
# * See `ADI::ServiceContainer` for documentation on working directly with the SC.
# * See `ADI::Injectable` for documentation on auto injecting services into non service types.
#
# NOTE: It is highly recommended to use interfaces as opposed to concrete types when defining the initializers for both services and non-services.
# Using interfaces allows changing the functionality of a type by just changing what service gets injected into it.
# See this [blog post](https://dev.to/blacksmoke16/dependency-injection-in-crystal-2d66#plug-and-play) for an example of this.
module Athena::DI
  # Stores metadata associated with a specific service.
  #
  # The type of the service affects how it behaves within the container.  When a `struct` service is retrieved or injected into a type, it will be a copy of the one in the SC (passed by value).
  # This means that changes made to it in one type, will _NOT_ be reflected in other types.  A `class` service on the other hand will be a reference to the one in the SC.  This allows it
  # to share state between types.
  #
  # ## Fields
  # * `name : String`- The name that should be used for the service.  Defaults to the type's name snake cased.
  # * `public : Bool` - If the service should be directly accessible from the container.  Defaults to `false`.
  # * `tags : Array(String)` - Tags that should be assigned to the service.  Defaults to an empty array.
  #
  # ## Examples
  #
  # ### Without Arguments
  # If the service doesn't have any arguments then the annotation can be applied without any extra options.
  #
  # ```
  # @[ADI::Register]
  # class Store
  #   include ADI::Service
  #
  #   property uuid : String? = nil
  # end
  # ```
  #
  # ### Multiple Services of the Same Type
  # If multiple `ADI::Register` annotations are applied onto the same type, multiple services will be registered based on that type.
  # The name of each service must be explicitly set, otherwise only the last annotation would work.
  #
  # ```
  # @[ADI::Register("GOOGLE", "Google", name: "google")]
  # @[ADI::Register("FACEBOOK", "Facebook", name: "facebook")]
  # struct FeedPartner
  #   include ADI::Service
  #
  #   getter id : String
  #   getter name : String
  #
  #   def initialize(@id : String, @name : String); end
  # end
  # ```
  #
  # ### Service Dependencies
  # Services can be injected into another service by prefixing a string containing the service's name, prefixed with an `@` symbol.
  # This syntax also works within arrays if you wished to inject a static set of services.
  #
  # ```
  # @[ADI::Register]
  # class Store
  #   include ADI::Service
  #
  #   property uuid : String? = nil
  # end
  #
  # @[ADI::Register("@store")]
  # struct SomeService
  #   include ADI::Service
  #
  #   def initialize(@store : Store); end
  # end
  # ```
  #
  # ### Tagged Services
  # Services can be injected into another service based on a tag by prefixing the name of the tag with an `!` symbol.
  # This will provide an array of all services that have that tag.  It is advised to use this with a parent type/interface to type the ivar with.
  #
  # NOTE: The parent type must also include `ADI::Service`.
  #
  # ```
  # abstract class SomeParentType
  #   include ADI::Service
  # end
  #
  # @[ADI::Register(tags: ["a_type"])]
  # class SomeTypeOne < SomeParentType
  #   include ADI::Service
  # end
  #
  # @[ADI::Register(tags: ["a_type"])]
  # class SomeTypeTwo < SomeParentType
  #   include ADI::Service
  # end
  #
  # @[ADI::Register("!a_type")]
  # struct SomeService
  #   include ADI::Service
  #
  #   def initialize(@types : Array(SomeParentType)); end
  # end
  # ```
  annotation Register; end

  # Used to designate a type as a service.
  #
  # See `ADI::Register` for more details.
  module Service; end

  # Returns the `Athena::DI::ServiceContainer` for the current fiber.
  def self.container : Athena::DI::ServiceContainer
    Fiber.current.container
  end

  # Adds a new constructor that resolves the required services based on type and name.
  #
  # Can be included into a `class`/`struct` in order to automatically inject the required services from the container based on the type's initializer.
  #
  # Service lookup is based on the type restriction and name of the initializer arguments.  If there is only a single service
  # of the required type, then that service is used.  If there are multiple services of the required type then the name of the argument's name is used.
  # An exception is raised if a service was not able to be resolved.
  #
  # ## Examples
  #
  # ### Default Usage
  #
  # ```
  # @[ADI::Register]
  # class Store
  #   include ADI::Service
  #
  #   property uuid : String = "UUID"
  # end
  #
  # class MyNonService
  #   include ADI::Injectable
  #
  #   getter store : Store
  #
  #   def initialize(@store : Store); end
  # end
  #
  # MyNonService.new.store.uuid # => "UUID"
  # ```
  #
  # ### Non Service Dependencies
  #
  # Named arguments take precedence.  This allows dependencies to be supplied explicitly without going through the resolving process; such as for testing.
  # ```
  # @[ADI::Register]
  # class Store
  #   include ADI::Service
  #
  #   property uuid : String = "UUID"
  # end
  #
  # class MyNonService
  #   include ADI::Injectable
  #
  #   getter store : Store
  #   getter id : String
  #
  #   def initialize(@store : Store, @id : String); end
  # end
  #
  # service = MyNonService.new(id: "FOO")
  # service.store.uuid # => "UUID"
  # service.id         # => "FOO"
  # ```
  module Injectable
    macro included
      macro finished
        {% verbatim do %}
          {% if initializer = @type.methods.find &.name.stringify.==("initialize") %}
            # Auto generated via `ADI::Injectable` module.
            def self.new(**args)
              new(
                {% for arg in initializer.args %}
                  {{arg.name.id}}: args[{{arg.name.symbolize}}]? || Athena::DI.container.resolve({{arg.restriction.id}}, {{arg.name.stringify}}),
                {% end %}
              )
            end
          {% end %}
        {% end %}
      end
    end
  end
end
