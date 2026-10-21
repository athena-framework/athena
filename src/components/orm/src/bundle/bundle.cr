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
#
# ## Migrations
#
# Requiring `athena-orm/migrations` also wires the services of [migrations](/ORM/database_migrations/), and their `orm:migrations:*` commands when the [console bundle](/Console/Bundle/) is registered.
# Their namespace and directory must then be configured:
#
# ```
# require "athena-orm/bundle"
# require "athena-orm/migrations"
#
# ADI.configure({
#   orm: {
#     url:        ENV["DATABASE_URL"],
#     migrations: {
#       namespace: "App::Migrations",
#       directory: "#{__DIR__}/migrations",
#     },
#   },
# })
# ```
#
# See `Schema::Migrations` for the other configuration properties.
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

    # Configures the migrations, which are only used when `athena-orm/migrations` is required, see `AORM::Migrations`.
    module Migrations
      include ADI::Extension::Schema

      # The namespace of the application's migrations, e.g. `App::Migrations`.
      # Only the migrations in it are executed, and new ones are generated in it.
      #
      # Required when `athena-orm/migrations` is required.
      property namespace : String? = nil

      # The directory new migrations are generated in, e.g. `"#{__DIR__}/migrations"`.
      # A relative path is relative to the directory the command runs in.
      #
      # Required when `athena-orm/migrations` is required.
      property directory : String? = nil

      # Whether new migrations are generated to run in a transaction, see `AORM::Migrations::AbstractMigration#transactional?`.
      property transactional : Bool = true

      # Configures the table executed migrations are recorded in, see `AORM::Migrations::Metadata::Storage::TableMetadataStorageConfiguration`.
      module Storage
        include ADI::Extension::Schema

        # The name of the table.
        property table_name : String = "athena_orm_migration_versions"

        # The name of the column holding the versions of the executed migrations.
        property version_column_name : String = "version"

        # The length of the version column, which limits the length of the fully qualified names of migrations.
        property version_column_length : Int32 = 191

        # The name of the column holding the time each migration was executed at.
        property executed_at_column_name : String = "executed_at"

        # The name of the column holding how long executing each migration took, in milliseconds.
        property execution_time_column_name : String = "execution_time"
      end
    end
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
              public:     true,
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

          # Migrations
          {%
            if parse_type("Athena::ORM::Migrations").resolve?
              migrations_cfg = cfg["migrations"]
              storage_cfg = migrations_cfg["storage"]

              unless migrations_cfg["namespace"]
                raise "Required configuration property 'orm.migrations.namespace : String' must be provided when 'athena-orm/migrations' is required."
              end

              unless migrations_cfg["directory"]
                raise "Required configuration property 'orm.migrations.directory : String' must be provided when 'athena-orm/migrations' is required."
              end
              namespace_prefix = "#{migrations_cfg["namespace"].id}::"

              migration_classes = Athena::ORM::Migrations::AbstractMigration.all_subclasses.select do |migration_class|
                !migration_class.abstract? && migration_class.name.stringify.starts_with?(namespace_prefix)
              end

              configuration = "Athena::ORM::Migrations::Configuration.new(#{migrations_cfg["namespace"]}, #{migrations_cfg["directory"]}, #{migrations_cfg["transactional"]})".id
              storage_configuration = "Athena::ORM::Migrations::Metadata::Storage::TableMetadataStorageConfiguration.new(#{storage_cfg["table_name"]}, #{storage_cfg["version_column_name"]}, #{storage_cfg["version_column_length"]}, #{storage_cfg["executed_at_column_name"]}, #{storage_cfg["execution_time_column_name"]})".id

              SERVICE_HASH[connection_id = "athena_orm_connection"] = {
                class:      Athena::ORM::Connection,
                factory:    {Athena::ORM::Bundle::Registry, "connection"},
                parameters: {
                  registry: {value: registry_id.id},
                },
              }

              SERVICE_HASH[metadata_storage_id = "athena_orm_migrations_metadata_storage"] = {
                class:      Athena::ORM::Migrations::Metadata::Storage::TableMetadataStorage,
                public:     true,
                parameters: {
                  connection:    {value: connection_id.id},
                  configuration: {value: storage_configuration},
                },
              }

              ALIASES[Athena::ORM::Migrations::Metadata::Storage::Interface] = [
                {id: metadata_storage_id, public: false},
              ]

              SERVICE_HASH[repository_id = "athena_orm_migrations_repository"] = {
                class:      Athena::ORM::Migrations::MigrationsRepository,
                parameters: {
                  migration_classes: {value: "[#{migration_classes.map(&.name).splat}] of Athena::ORM::Migrations::AbstractMigration.class".id},
                },
              }

              SERVICE_HASH[plan_calculator_id = "athena_orm_migrations_plan_calculator"] = {
                class:      Athena::ORM::Migrations::Version::MigrationPlanCalculator,
                public:     true,
                parameters: {
                  migrations_repository: {value: repository_id.id},
                  metadata_storage:      {value: metadata_storage_id.id},
                },
              }

              SERVICE_HASH[status_calculator_id = "athena_orm_migrations_status_calculator"] = {
                class:      Athena::ORM::Migrations::Version::MigrationStatusCalculator,
                parameters: {
                  migration_plan_calculator: {value: plan_calculator_id.id},
                  metadata_storage:          {value: metadata_storage_id.id},
                },
              }

              SERVICE_HASH[alias_resolver_id = "athena_orm_migrations_alias_resolver"] = {
                class:      Athena::ORM::Migrations::Version::AliasResolver,
                public:     true,
                parameters: {
                  migration_plan_calculator:   {value: plan_calculator_id.id},
                  metadata_storage:            {value: metadata_storage_id.id},
                  migration_status_calculator: {value: status_calculator_id.id},
                },
              }

              SERVICE_HASH[executor_id = "athena_orm_migrations_executor"] = {
                class:      Athena::ORM::Migrations::Version::Executor,
                parameters: {
                  metadata_storage: {value: metadata_storage_id.id},
                  connection:       {value: connection_id.id},
                },
              }

              SERVICE_HASH[migrator_id = "athena_orm_migrations_migrator"] = {
                class:      Athena::ORM::Migrations::Migrator,
                public:     true,
                parameters: {
                  executor: {value: executor_id.id},
                },
              }

              SERVICE_HASH[generator_id = "athena_orm_migrations_generator"] = {
                class:      Athena::ORM::Migrations::Generator,
                parameters: {
                  configuration: {value: configuration},
                },
              }

              SERVICE_HASH[class_name_generator_id = "athena_orm_migrations_class_name_generator"] = {
                class: Athena::ORM::Migrations::Generator::ClassNameGenerator,
              }

              # Requiring the Console component alone does not register its bundle, so check for the bundle to know commands are registered.
              if ADI::ServiceContainer::EXTENSIONS["console"]
                SERVICE_HASH[status_infos_helper_id = "athena_orm_migrations_status_infos_helper"] = {
                  class:      Athena::ORM::Migrations::Commands::MigrationStatusInfosHelper,
                  parameters: {
                    configuration:             {value: configuration},
                    storage_configuration:     {value: storage_configuration},
                    connection:                {value: connection_id.id},
                    alias_resolver:            {value: alias_resolver_id.id},
                    migration_plan_calculator: {value: plan_calculator_id.id},
                    status_calculator:         {value: status_calculator_id.id},
                    metadata_storage:          {value: metadata_storage_id.id},
                  },
                }

                SERVICE_HASH["athena_orm_migrations_commands_execute"] = {
                  class:      Athena::ORM::Migrations::Commands::Execute,
                  parameters: {
                    metadata_storage:          {value: metadata_storage_id.id},
                    migration_plan_calculator: {value: plan_calculator_id.id},
                    migrator:                  {value: migrator_id.id},
                  },
                }

                SERVICE_HASH["athena_orm_migrations_commands_generate"] = {
                  class:      Athena::ORM::Migrations::Commands::Generate,
                  parameters: {
                    configuration:        {value: configuration},
                    generator:            {value: generator_id.id},
                    class_name_generator: {value: class_name_generator_id.id},
                  },
                }

                SERVICE_HASH["athena_orm_migrations_commands_list"] = {
                  class:      Athena::ORM::Migrations::Commands::List,
                  parameters: {
                    migration_plan_calculator:     {value: plan_calculator_id.id},
                    metadata_storage:              {value: metadata_storage_id.id},
                    migration_status_infos_helper: {value: status_infos_helper_id.id},
                  },
                }

                SERVICE_HASH["athena_orm_migrations_commands_migrate"] = {
                  class:      Athena::ORM::Migrations::Commands::Migrate,
                  parameters: {
                    metadata_storage:            {value: metadata_storage_id.id},
                    migrations_repository:       {value: repository_id.id},
                    alias_resolver:              {value: alias_resolver_id.id},
                    migration_plan_calculator:   {value: plan_calculator_id.id},
                    migration_status_calculator: {value: status_calculator_id.id},
                    migrator:                    {value: migrator_id.id},
                  },
                }

                SERVICE_HASH["athena_orm_migrations_commands_status"] = {
                  class:      Athena::ORM::Migrations::Commands::Status,
                  parameters: {
                    migration_status_infos_helper: {value: status_infos_helper_id.id},
                  },
                }

                SERVICE_HASH["athena_orm_migrations_commands_sync_metadata_storage"] = {
                  class:      Athena::ORM::Migrations::Commands::SyncMetadataStorage,
                  parameters: {
                    metadata_storage: {value: metadata_storage_id.id},
                  },
                }

                SERVICE_HASH["athena_orm_migrations_commands_version"] = {
                  class:      Athena::ORM::Migrations::Commands::Version,
                  parameters: {
                    metadata_storage:          {value: metadata_storage_id.id},
                    migrations_repository:     {value: repository_id.id},
                    migration_plan_calculator: {value: plan_calculator_id.id},
                  },
                }
              end
            end
          %}
        {% end %}
      end
    end
  end
end
