# Integrates the ORM with the [dependency injection](/DependencyInjection/) component, such as within an [Athena Framework](/Framework/) application.
#
# Require `athena-orm/bundle` to register the bundle, then configure the URL of the database:
#
# ```
# require "athena"
# require "athena-orm/bundle"
#
# ADI.configure({
#   orm: {
#     url: ENV["DATABASE_URL"],
#   },
# })
# ```
#
# Each `AORM::EntityManagerInterface` that's injected is the entity manager of the current unit of work, such as a request, see `AORM::Bundle::Registry`:
#
# ```
# @[ADI::Register]
# class UserController < ATH::Controller
#   def initialize(@em : AORM::EntityManagerInterface); end
#
#   @[ARTA::Get("/user/{id}")]
#   def user(id : Int64) : User?
#     @em.find User, id
#   end
# end
# ```
@[ADI::Bundle("orm")]
struct Athena::ORM::Bundle < ADI::AbstractBundle
  # :nodoc:
  PASSES = [] of _

  # Represents the properties used to configure the ORM.
  module Schema
    include ADI::Extension::Schema

    # The URL of the database to connect to.
    # Connection pool options may be provided as query parameters, see the [crystal-db docs](https://crystal-lang.org/reference/database/connection_pool.html).
    property url : String
  end

  # :nodoc:
  module Extension
    macro included
      macro finished
        {% verbatim do %}
          {%
            cfg = CONFIG["orm"]

            SERVICE_HASH[registry_id = "athena_orm_registry"] = {
              class:      Athena::ORM::Bundle::Registry,
              parameters: {
                url: {value: cfg["url"]},
              },
            }

            SERVICE_HASH[entity_manager_id = "athena_orm_entity_manager"] = {
              class:      Athena::ORM::EntityManager,
              factory:    {Athena::ORM::Bundle::Registry, "entity_manager"},
              parameters: {
                registry: {value: registry_id.id},
              },
            }

            ALIASES[Athena::ORM::EntityManagerInterface] = [
              {id: entity_manager_id, public: false},
            ]
          %}
        {% end %}
      end
    end
  end
end
