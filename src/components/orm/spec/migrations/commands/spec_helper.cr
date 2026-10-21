require "athena-console"
require "athena-console/spec"
require "../spec_helper"

# The migrations services, as the bundle wires them, on a mock connection with migrations recorded in memory.
class MigrationsCommandsFixture
  getter wrapped : MockConnection = MockConnection.new
  getter connection : AORM::Connection
  getter storage : InMemoryMetadataStorage
  getter repository : AORM::Migrations::MigrationsRepository
  getter plan_calculator : AORM::Migrations::Version::MigrationPlanCalculator
  getter status_calculator : AORM::Migrations::Version::MigrationStatusCalculator
  getter alias_resolver : AORM::Migrations::Version::AliasResolver
  getter migrator : AORM::Migrations::Migrator

  def initialize(
    migration_classes : Array(AORM::Migrations::AbstractMigration.class) = [MigrationsSpec::Version1, MigrationsSpec::Version2, MigrationsSpec::Version3] of AORM::Migrations::AbstractMigration.class,
    @storage : InMemoryMetadataStorage = InMemoryMetadataStorage.new,
  )
    @connection = AORM::Connection.new @wrapped
    @repository = AORM::Migrations::MigrationsRepository.new migration_classes
    @plan_calculator = AORM::Migrations::Version::MigrationPlanCalculator.new @repository, @storage
    @status_calculator = AORM::Migrations::Version::MigrationStatusCalculator.new @plan_calculator, @storage
    @alias_resolver = AORM::Migrations::Version::AliasResolver.new @plan_calculator, @storage, @status_calculator
    @migrator = AORM::Migrations::Migrator.new AORM::Migrations::Version::Executor.new(@storage, @connection)
  end

  def status_infos_helper : AORM::Migrations::Commands::MigrationStatusInfosHelper
    AORM::Migrations::Commands::MigrationStatusInfosHelper.new(
      AORM::Migrations::Configuration.new("MigrationsSpec", "src/migrations"),
      AORM::Migrations::Metadata::Storage::TableMetadataStorageConfiguration.new,
      @connection,
      @alias_resolver,
      @plan_calculator,
      @status_calculator,
      @storage,
    )
  end

  def executed_versions : Array(String)
    @storage.executed_migrations.items.map &.version.to_s
  end
end
