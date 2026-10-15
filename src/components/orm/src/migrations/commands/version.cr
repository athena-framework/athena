# Records migrations as executed, or not, without executing them, such as to start using migrations on an existing database.
#
# ```text
# $ ./bin/console orm:migrations:version 'App::Migrations::Version20261014120000' --add
# $ ./bin/console orm:migrations:version --add --all
# ```
@[ACONA::AsCommand("orm:migrations:version", description: "Manually add and delete migration versions from the version table.")]
class Athena::ORM::Migrations::Commands::Version < Athena::ORM::Migrations::Commands::AbstractCommand
  @mark_migrated : Bool = false

  def initialize(
    @metadata_storage : AORM::Migrations::Metadata::Storage::Interface,
    @migrations_repository : AORM::Migrations::MigrationsRepository,
    @migration_plan_calculator : AORM::Migrations::Version::MigrationPlanCalculator,
  )
    super()
  end

  protected def configure : Nil
    self
      .argument("version", description: "The version to add or delete.")
      .option("add", description: "Add the specified version.")
      .option("delete", description: "Delete the specified version.")
      .option("all", description: "Apply to all the versions.")
      .option("range-from", value_mode: :required, description: "Apply from specified version.")
      .option("range-to", value_mode: :required, description: "Apply to specified version.")
      .help(<<-HELP)
        The <info>%command.name%</info> command allows you to manually add, delete or synchronize migration versions from the version table:

            <info>%command.full_name% MIGRATION-FQCN --add</info>

        If you want to delete a version you can use the <comment>--delete</comment> option:

            <info>%command.full_name% MIGRATION-FQCN --delete</info>

        If you want to synchronize by adding or deleting all migration versions available in the version table you can use the <comment>--all</comment> option:

            <info>%command.full_name% --add --all</info>
            <info>%command.full_name% --delete --all</info>

        If you want to synchronize by adding or deleting some range of migration versions available in the version table you can use the <comment>--range-from/--range-to</comment> option:

            <info>%command.full_name% --add --range-from=MIGRATION-FQCN --range-to=MIGRATION-FQCN</info>
            <info>%command.full_name% --delete --range-from=MIGRATION-FQCN --range-to=MIGRATION-FQCN</info>

        You can also execute this command without a warning message which you need to interact with:

            <info>%command.full_name% --no-interaction</info>
        HELP
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    if !input.option("add", Bool) && !input.option("delete", Bool)
      raise AORM::Migrations::Exception::InvalidOptionUsage.new "You must specify whether you want to --add or --delete the specified version."
    end

    @mark_migrated = input.option "add", Bool

    if input.interactive?
      question = "WARNING! You are about to add, delete or synchronize migration versions from the version table that could result in data lost. Are you sure you wish to continue?"

      if self.io.confirm question
        self.mark_versions input
      else
        self.io.error "Migration cancelled!"
      end
    else
      self.mark_versions input
    end

    ACON::Command::Status::SUCCESS
  end

  # ameba:disable Metrics/CyclomaticComplexity
  private def mark_versions(input : ACON::Input::Interface) : Nil
    affected_version = input.argument "version"
    all_option = input.option "all", Bool
    range_from_option = input.option "range-from"
    range_to_option = input.option "range-to"

    if all_option && (range_from_option || range_to_option)
      raise AORM::Migrations::Exception::InvalidOptionUsage.new "Options --all and --range-to/--range-from both used. You should use only one of them."
    end

    if range_from_option.nil? ^ range_to_option.nil?
      raise AORM::Migrations::Exception::InvalidOptionUsage.new "Options --range-to and --range-from should be used together."
    end

    executed_migrations = @metadata_storage.executed_migrations
    available_versions = @migration_plan_calculator.migrations

    if all_option
      if input.option "delete", Bool
        executed_migrations.items.each do |executed_migration|
          self.mark input, executed_migration.version, false, executed_migrations
        end
      end

      available_versions.items.each do |available_migration|
        self.mark input, available_migration.version, true, executed_migrations
      end
    elsif affected_version
      self.mark input, AORM::Migrations::Version.new(affected_version), false, executed_migrations
    elsif range_from_option && range_to_option
      migrate = false

      available_versions.items.each do |available_migration|
        migrate = true if available_migration.version.to_s == range_from_option

        self.mark input, available_migration.version, true, executed_migrations if migrate

        break if available_migration.version.to_s == range_to_option
      end
    else
      raise AORM::Migrations::Exception::InvalidOptionUsage.new "You must specify the version or use the --all argument."
    end
  end

  private def mark(input : ACON::Input::Interface, version : AORM::Migrations::Version, all : Bool, executed_migrations : AORM::Migrations::Metadata::ExecutedMigrationsList) : Nil
    available = @migrations_repository.has_migration? version

    unless available
      raise AORM::Migrations::Exception::UnknownMigrationVersion.new version.to_s unless input.option "delete", Bool

      question = "WARNING! You are about to delete a migration version from the version table that has no corresponding migration file." \
                 "Do you want to delete this migration from the migrations table?"

      if self.io.confirm question
        @metadata_storage.complete AORM::Migrations::Version::ExecutionResult.new(version, :down)
        self.io.text "<info>#{version}</info> deleted from the version table.\n"

        return
      end
    end

    if @mark_migrated && executed_migrations.has_migration?(version)
      raise AORM::Migrations::Exception::VersionAlreadyExists.new version unless all

      return
    end

    if !@mark_migrated && !executed_migrations.has_migration?(version)
      raise AORM::Migrations::Exception::VersionDoesNotExist.new version unless all

      return
    end

    if @mark_migrated
      @metadata_storage.complete AORM::Migrations::Version::ExecutionResult.new(version, :up)
      self.io.text "<info>#{version}</info> added to the version table.\n"
    else
      @metadata_storage.complete AORM::Migrations::Version::ExecutionResult.new(version, :down)
      self.io.text "<info>#{version}</info> deleted from the version table.\n"
    end
  end
end
