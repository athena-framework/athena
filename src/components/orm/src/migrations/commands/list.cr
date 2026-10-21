# Displays all the migrations, available or executed, with their status.
#
# ```text
# $ ./bin/console orm:migrations:list
# ```
@[ACONA::AsCommand("orm:migrations:list", description: "Display a list of all available migrations and their status.")]
class Athena::ORM::Migrations::Commands::List < Athena::ORM::Migrations::Commands::AbstractCommand
  def initialize(
    @migration_plan_calculator : AORM::Migrations::Version::MigrationPlanCalculator,
    @metadata_storage : AORM::Migrations::Metadata::Storage::Interface,
    @migration_status_infos_helper : AORM::Migrations::Commands::MigrationStatusInfosHelper,
  )
    super()
  end

  protected def configure : Nil
    self
      .help(<<-HELP)
        The <info>%command.name%</info> command outputs a list of all available migrations and their status:

            <info>%command.full_name%</info>
        HELP
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    available_versions = @migration_plan_calculator.migrations.items.map &.version
    executed_versions = @metadata_storage.executed_migrations.items.map &.version

    @migration_status_infos_helper.list_versions (available_versions + executed_versions).uniq.sort_by!(&.to_s), output

    ACON::Command::Status::SUCCESS
  end
end
