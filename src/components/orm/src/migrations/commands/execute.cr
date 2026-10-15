# Applies or reverts specific migrations, whether or not they have already been executed.
#
# ```text
# $ ./bin/console orm:migrations:execute 'App::Migrations::Version20261014120000' --down
# ```
@[ACONA::AsCommand("orm:migrations:execute", description: "Execute one or more migration versions up or down manually.")]
class Athena::ORM::Migrations::Commands::Execute < Athena::ORM::Migrations::Commands::AbstractCommand
  def initialize(
    @metadata_storage : AORM::Migrations::Metadata::Storage::Interface,
    @migration_plan_calculator : AORM::Migrations::Version::MigrationPlanCalculator,
    @migrator : AORM::Migrations::Migrator,
  )
    super()
  end

  protected def configure : Nil
    self
      .argument("versions", mode: ACON::Input::Argument::Mode[:required, :is_array], description: "The versions to execute.")
      .option("dry-run", description: "Execute the migration as a dry run.")
      .option("up", description: "Execute the migration up.")
      .option("down", description: "Execute the migration down.")
      .option("query-time", description: "Time all the queries individually.")
      .help(<<-HELP)
        The <info>%command.name%</info> command executes migration versions up or down manually:

            <info>%command.full_name% FQCN</info>

        You can show more information about the process by increasing the verbosity level. To see the
        executed queries, set the level to debug with <comment>-vv</comment>:

            <info>%command.full_name% FQCN -vv</info>

        If no <comment>--up</comment> or <comment>--down</comment> option is specified it defaults to up:

            <info>%command.full_name% FQCN --down</info>

        You can also execute the migration as a <comment>--dry-run</comment>:

            <info>%command.full_name% FQCN --dry-run</info>

        Or you can also execute the migration without a warning message which you need to interact with:

            <info>%command.full_name% FQCN --no-interaction</info>

        All the previous commands accept multiple migration versions, allowing you run execute more than
        one migration at once:

            <info>%command.full_name% FQCN-1 FQCN-2 ...FQCN-n </info>
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

      return ACON::Command::Status::FAILURE
    end

    @metadata_storage.ensure_initialized

    versions = input.argument "versions", Array(String)
    direction = input.option("down", Bool) ? AORM::Migrations::Version::Direction::DOWN : AORM::Migrations::Version::Direction::UP

    plan = @migration_plan_calculator.plan_for_versions versions.map { |version| AORM::Migrations::Version.new version }, direction

    AORM::Migrations::Log.notice { "Executing#{configuration.dry_run? ? " (dry-run)" : ""} #{versions.join ", "} #{plan.direction}" }

    @migrator.migrate plan, configuration

    self.io.success "Successfully migrated version(s): #{versions.join ", "}: [#{plan.direction.to_s.upcase}]"
    self.io.new_line

    ACON::Command::Status::SUCCESS
  end
end
