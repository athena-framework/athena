# Plans which migrations to execute, and in which direction, to reach a version.
class Athena::ORM::Migrations::Version::MigrationPlanCalculator
  def initialize(
    @migrations_repository : AORM::Migrations::MigrationsRepository,
    @metadata_storage : AORM::Migrations::Metadata::Storage::Interface,
  ); end

  # Returns the plan to execute the migrations with the provided *versions* in *direction*, whether or not they have already been executed.
  # They're planned in order of their versions, or in reverse order when reverting them.
  #
  # Raises `AORM::Migrations::Exception::MigrationClassNotFound` if there's no migration with one of the *versions*.
  def plan_for_versions(versions : Enumerable(AORM::Migrations::Version::Version), direction : AORM::Migrations::Version::Direction) : AORM::Migrations::Metadata::MigrationPlanList
    migrations_to_check = self.arrange_migrations_for_direction direction, self.migrations
    available_migrations = migrations_to_check.select { |migration| versions.includes? migration.version }

    plan_items = available_migrations.map do |migration|
      AORM::Migrations::Metadata::MigrationPlan.new migration.version, migration.migration_class, direction
    end

    if plan_items.size != versions.size
      planned_versions = plan_items.map &.version

      raise AORM::Migrations::Exception::MigrationClassNotFound.new (versions.to_a - planned_versions).first?.to_s
    end

    AORM::Migrations::Metadata::MigrationPlanList.new plan_items, direction
  end

  # Returns the plan to migrate the database to the version *to*, applying the migrations up to and including it that haven't been executed, or reverting the executed ones after it.
  # A version of `0` reverts every executed migration.
  #
  # Raises `AORM::Migrations::Exception::MigrationClassNotFound` if there's no migration with the version *to*.
  def plan_until_version(to : AORM::Migrations::Version::Version) : AORM::Migrations::Metadata::MigrationPlanList
    if to.to_s != "0" && !@migrations_repository.has_migration?(to)
      raise AORM::Migrations::Exception::MigrationClassNotFound.new to.to_s
    end

    available_migrations = self.migrations
    executed_migrations = @metadata_storage.executed_migrations

    direction = self.find_direction to, executed_migrations, available_migrations
    migrations_to_check = self.arrange_migrations_for_direction direction, available_migrations
    to_execute = self.find_migrations_to_execute to, migrations_to_check, direction, executed_migrations

    AORM::Migrations::Metadata::MigrationPlanList.new(
      to_execute.map { |migration| AORM::Migrations::Metadata::MigrationPlan.new migration.version, migration.migration_class, direction },
      direction
    )
  end

  # Returns the available migrations, ordered by version.
  def migrations : AORM::Migrations::Metadata::AvailableMigrationsList
    AORM::Migrations::Metadata::AvailableMigrationsList.new @migrations_repository.migrations.items.sort_by(&.version.to_s)
  end

  private def find_direction(
    to : AORM::Migrations::Version::Version,
    executed_migrations : AORM::Migrations::Metadata::ExecutedMigrationsList,
    available_migrations : AORM::Migrations::Metadata::AvailableMigrationsList,
  ) : AORM::Migrations::Version::Direction
    return AORM::Migrations::Version::Direction::DOWN if to.to_s == "0"

    available_migrations.items.each do |available_migration|
      break if available_migration.version == to

      return AORM::Migrations::Version::Direction::UP unless executed_migrations.has_migration? available_migration.version
    end

    if executed_migrations.has_migration?(to) && executed_migrations.last.version != to
      return AORM::Migrations::Version::Direction::DOWN
    end

    AORM::Migrations::Version::Direction::UP
  end

  private def arrange_migrations_for_direction(
    direction : AORM::Migrations::Version::Direction,
    available_migrations : AORM::Migrations::Metadata::AvailableMigrationsList,
  ) : Array(AORM::Migrations::Metadata::AvailableMigration)
    direction.up? ? available_migrations.items : available_migrations.items.reverse
  end

  private def find_migrations_to_execute(
    to : AORM::Migrations::Version::Version,
    migrations_to_check : Array(AORM::Migrations::Metadata::AvailableMigration),
    direction : AORM::Migrations::Version::Direction,
    executed_migrations : AORM::Migrations::Metadata::ExecutedMigrationsList,
  ) : Array(AORM::Migrations::Metadata::AvailableMigration)
    to_execute = [] of AORM::Migrations::Metadata::AvailableMigration

    migrations_to_check.each do |available_migration|
      break if direction.down? && available_migration.version == to

      executed = executed_migrations.has_migration? available_migration.version

      if (direction.up? && !executed) || (direction.down? && executed)
        to_execute << available_migration
      end

      break if direction.up? && available_migration.version == to
    end

    to_execute
  end
end
