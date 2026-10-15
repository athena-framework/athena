require "./spec_helper"

private MIGRATIONS_PREAMBLE = %(require "./spec_helper.cr"\nrequire "../../src/migrations")

private def assert_compiles(code : String, *, preamble : String = MIGRATIONS_PREAMBLE, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles code, line: line, preamble: preamble
end

describe AORM::Bundle, tags: "compiled" do
  it "wires the migrations of the configured namespace" do
    assert_compiles <<-'CR'
      class App::Migrations::Version1 < AORM::Migrations::AbstractMigration
        def up : Nil
        end
      end

      abstract class App::Migrations::Base < AORM::Migrations::AbstractMigration
      end

      class Other::Migrations::Version1 < AORM::Migrations::AbstractMigration
        def up : Nil
        end
      end

      @[ADI::Register(public: true)]
      class MigratorConsumer
        def initialize(
          @migrator : AORM::Migrations::Migrator,
          @alias_resolver : AORM::Migrations::Version::AliasResolver,
          @metadata_storage : AORM::Migrations::Metadata::Storage::Interface,
          @generator : AORM::Migrations::Generator,
        ); end
      end

      ADI.container.migrator_consumer

      macro finished
        macro finished
          \{%
             repository = ADI::ServiceContainer::SERVICE_HASH["athena_orm_migrations_repository"]
             classes = repository["parameters"]["migration_classes"]["value"].stringify
             storage = ADI::ServiceContainer::SERVICE_HASH["athena_orm_migrations_metadata_storage"]["parameters"]["configuration"]["value"].stringify
             generator = ADI::ServiceContainer::SERVICE_HASH["athena_orm_migrations_generator"]["parameters"]["configuration"]["value"].stringify
          %}
          ASPEC.compile_time_assert(\{{ classes == "[App::Migrations::Version1] of Athena::ORM::Migrations::AbstractMigration.class" }}, "Expected only the concrete migrations of the configured namespace")
          ASPEC.compile_time_assert(\{{ storage.includes?(%("athena_orm_migration_versions", "version", 191, "executed_at", "execution_time")) }}, "Expected the default storage configuration")
          ASPEC.compile_time_assert(\{{ generator.includes?(%("App::Migrations", "src/migrations", true)) }}, "Expected the default configuration")
          ASPEC.compile_time_assert(\{{ !ADI::ServiceContainer::SERVICE_HASH.keys.includes?("athena_orm_migrations_commands_migrate") }}, "Expected no commands without the console bundle")
        end
      end
    CR
  end

  it "uses the configured namespace, directory and storage" do
    assert_compiles <<-'CR', preamble: %(require "../spec_helper.cr"\nrequire "../../src/bundle"\nrequire "../../src/migrations")
      ADI.configure({
        orm: {
          url:        "mock://",
          migrations: {
            namespace:     "Db::Migrations",
            directory:     "db/migrations",
            transactional: false,
            storage:       {
              table_name:            "migrations",
              version_column_length: 255,
            },
          },
        },
      })

      class Db::Migrations::Version1 < AORM::Migrations::AbstractMigration
        def up : Nil
        end
      end

      class App::Migrations::Version1 < AORM::Migrations::AbstractMigration
        def up : Nil
        end
      end

      @[ADI::Register(public: true)]
      class GeneratorConsumer
        def initialize(@generator : AORM::Migrations::Generator, @migrator : AORM::Migrations::Migrator); end
      end

      ADI.container.generator_consumer

      macro finished
        macro finished
          \{%
             classes = ADI::ServiceContainer::SERVICE_HASH["athena_orm_migrations_repository"]["parameters"]["migration_classes"]["value"].stringify
             storage = ADI::ServiceContainer::SERVICE_HASH["athena_orm_migrations_metadata_storage"]["parameters"]["configuration"]["value"].stringify
             generator = ADI::ServiceContainer::SERVICE_HASH["athena_orm_migrations_generator"]["parameters"]["configuration"]["value"].stringify
          %}
          ASPEC.compile_time_assert(\{{ classes == "[Db::Migrations::Version1] of Athena::ORM::Migrations::AbstractMigration.class" }}, "Expected only the migrations of the configured namespace")
          ASPEC.compile_time_assert(\{{ storage.includes?(%("migrations", "version", 255, "executed_at", "execution_time")) }}, "Expected the configured storage")
          ASPEC.compile_time_assert(\{{ generator.includes?(%("Db::Migrations", "db/migrations", false)) }}, "Expected the configured namespace and directory")
        end
      end
    CR
  end

  it "registers the commands with the console bundle" do
    assert_compiles <<-'CR', preamble: %(require "athena-console/bundle"\n#{MIGRATIONS_PREAMBLE})
      ACON::Application.new "Specs", "0.1.0", ADI.container

      macro finished
        macro finished
          \{%
             commands = %w(execute generate list migrate status sync_metadata_storage version)
             missing = commands.reject { |command| ADI::ServiceContainer::SERVICE_HASH.keys.includes?("athena_orm_migrations_commands_#{command.id}") }
          %}
          ASPEC.compile_time_assert(\{{ missing.empty? }}, "Expected every migrations command to be registered")
        end
      end
    CR
  end

  it "requires the namespace when migrations are required" do
    ASPEC::Methods.assert_compile_time_error "Required configuration property 'orm.migrations.namespace : String' must be provided when 'athena-orm/migrations' is required.", <<-'CR', preamble: %(require "../spec_helper.cr"\nrequire "../../src/bundle"\nrequire "../../src/migrations")
      ADI.configure({
        orm: {
          url: "mock://",
        },
      })

      ADI.container
    CR
  end

  it "does not wire migrations unless they're required" do
    assert_compiles <<-'CR', preamble: %(require "./spec_helper.cr")
      macro finished
        macro finished
          ASPEC.compile_time_assert(\{{ !ADI::ServiceContainer::SERVICE_HASH.keys.includes?("athena_orm_migrations_repository") }}, "Expected no migrations services")
        end
      end
    CR
  end
end
