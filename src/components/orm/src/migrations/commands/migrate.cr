# Migrates the database to a version, the latest one by default, applying or reverting the migrations in between.
#
# ```text
# $ ./bin/console orm:migrations:migrate
# $ ./bin/console orm:migrations:migrate prev
# $ ./bin/console orm:migrations:migrate 'App::Migrations::Version20261014120000' --dry-run
# ```
#
# See `AORM::Migrations::Version::AliasResolver` for the aliases a version may be given as.
@[ACONA::AsCommand("orm:migrations:migrate", description: "Execute a migration to a specified version or the latest available version.")]
class Athena::ORM::Migrations::Commands::Migrate < Athena::ORM::Migrations::Commands::AbstractCommand
  def initialize(
    @metadata_storage : AORM::Migrations::Metadata::Storage::Interface,
    @migrations_repository : AORM::Migrations::MigrationsRepository,
    @alias_resolver : AORM::Migrations::Version::AliasResolver,
    @migration_plan_calculator : AORM::Migrations::Version::MigrationPlanCalculator,
    @migration_status_calculator : AORM::Migrations::Version::MigrationStatusCalculator,
    @migrator : AORM::Migrations::Migrator,
  )
    super()
  end

  protected def configure : Nil
    self
      .argument("version", description: "The version FQCN or alias (first, prev, next, latest) to migrate to.", default: "latest")
      .option("dry-run", description: "Execute the migration as a dry run.")
      .option("query-time", description: "Time all the queries individually.")
      .option("allow-no-migration", description: "Do not throw an exception if no migration is available.")
      .help(<<-HELP)
        The <info>%command.name%</info> command executes a migration to a specified version or the latest available version:

            <info>%command.full_name%</info>

        You can show more information about the process by increasing the verbosity level. To see the
        executed queries, set the level to debug with <comment>-vv</comment>:

            <info>%command.full_name% -vv</info>

        You can optionally manually specify the version you wish to migrate to:

            <info>%command.full_name% FQCN</info>

        You can specify the version you wish to migrate to using an alias:

            <info>%command.full_name% prev</info>
            <info>These alias are defined: first, latest, prev, current and next</info>

        You can specify the version you wish to migrate to using a number against the current version:

            <info>%command.full_name% current+3</info>

        You can also execute the migration as a <comment>--dry-run</comment>:

            <info>%command.full_name% FQCN --dry-run</info>

        Or you can also execute the migration without a warning message which you need to interact with <comment>--no-interaction</comment>:

            <info>%command.full_name% --no-interaction</info>

        You can also time all the different queries if you want to know which one is taking so long with <comment>--query-time</comment>:

            <info>%command.full_name% --query-time</info>

        You can skip throwing an exception if no migration is available with <comment>--allow-no-migration</comment>:

            <info>%command.full_name% --allow-no-migration</info>
        HELP
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    configuration = AORM::Migrations::MigratorConfiguration.new(
      dry_run: input.option("dry-run", Bool),
      time_all_queries: input.option("query-time", Bool),
    )

    question = "WARNING! You are about to execute a migration that could result in schema changes and data loss. Are you sure you wish to continue?"

    if !configuration.dry_run? && !self.can_execute?(question, input)
      self.io.error "Migration cancelled!"

      return ACON::Command::Status.new 3
    end

    @metadata_storage.ensure_initialized

    allow_no_migration = input.option "allow-no-migration", Bool
    version_alias = input.argument "version", String

    if @migrations_repository.migrations.size.zero?
      message = %(The version "#{version_alias}" couldn't be reached, there are no registered migrations.)

      if allow_no_migration
        self.io.warning message

        return ACON::Command::Status::SUCCESS
      end

      self.io.error message

      return ACON::Command::Status::FAILURE
    end

    begin
      version = @alias_resolver.resolve_version_alias version_alias
    rescue AORM::Migrations::Exception::UnknownMigrationVersion
      self.io.error "Unknown version: #{ACON::Formatter::Output.escape version_alias}"

      return ACON::Command::Status::FAILURE
    rescue AORM::Migrations::Exception::NoMigrationsToExecute | AORM::Migrations::Exception::NoMigrationsFoundWithCriteria
      return self.exit_for_alias version_alias
    end

    executed_unavailable_migrations = @migration_status_calculator.executed_unavailable_migrations

    unless self.check_executed_unavailable_migrations(executed_unavailable_migrations, input)
      return ACON::Command::Status.new 3
    end

    plan = @migration_plan_calculator.plan_until_version version

    return self.exit_for_alias version_alias if plan.size.zero?

    AORM::Migrations::Log.notice { "Migrating#{configuration.dry_run? ? " (dry-run)" : ""} #{plan.direction} to #{version}" }

    @migrator.migrate plan, configuration

    self.io.success "Successfully migrated to version: #{version}"
    self.io.new_line

    ACON::Command::Status::SUCCESS
  end

  private def check_executed_unavailable_migrations(executed_unavailable_migrations : AORM::Migrations::Metadata::ExecutedMigrationsList, input : ACON::Input::Interface) : Bool
    return true if executed_unavailable_migrations.size.zero?

    self.io.warning "You have #{executed_unavailable_migrations.size} previously executed migrations in the database that are not registered migrations."

    executed_unavailable_migrations.items.each do |executed_unavailable_migration|
      self.io.text "<comment>>></comment> #{executed_unavailable_migration.executed_at.try &.to_s("%F %T")} (<comment>#{executed_unavailable_migration.version}</comment>)"
    end

    unless self.can_execute? "Are you sure you wish to continue?", input
      self.io.error "Migration cancelled!"

      return false
    end

    true
  end

  private def exit_for_alias(version_alias : String) : ACON::Command::Status
    version = @alias_resolver.resolve_version_alias "current"

    # Allow meaningful message when latest version already reached.
    if version_alias.in? "current", "latest", "first"
      self.io.success %(Already at the #{version_alias} version ("#{version}"))
    elsif version_alias.in?("next", "prev") || version_alias.starts_with?("current")
      self.io.error %(The version "#{version_alias}" couldn't be reached, you are at version "#{version}")
    else
      self.io.success %(You are already at version "#{version}")
    end

    ACON::Command::Status::SUCCESS
  end
end
