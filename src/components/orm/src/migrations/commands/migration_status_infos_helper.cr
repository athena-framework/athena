# Renders the status of the migrations, as shown by `AORM::Migrations::Commands::Status` and `AORM::Migrations::Commands::List`.
class Athena::ORM::Migrations::Commands::MigrationStatusInfosHelper
  def initialize(
    @configuration : AORM::Migrations::Configuration,
    @storage_configuration : AORM::Migrations::Metadata::Storage::TableMetadataStorageConfiguration,
    @connection : AORM::Connection,
    @alias_resolver : AORM::Migrations::Version::AliasResolver,
    @migration_plan_calculator : AORM::Migrations::Version::MigrationPlanCalculator,
    @status_calculator : AORM::Migrations::Version::MigrationStatusCalculator,
    @metadata_storage : AORM::Migrations::Metadata::Storage::Interface,
  ); end

  # Renders a table of *versions*, with whether each was executed, when, how long it took, and its description.
  def list_versions(versions : Enumerable(AORM::Migrations::Version), output : ACON::Output::Interface) : Nil
    table = ACON::Helper::Table.new output
    table.headers([
      [ACON::Helper::Table::Cell.new("Migration Versions", colspan: 5)] of ACON::Helper::Table::CellType,
      ["Migration", "Status", "Migrated At", "Execution Time", "Description"] of ACON::Helper::Table::CellType,
    ])

    executed_migrations = @metadata_storage.executed_migrations
    available_migrations = @migration_plan_calculator.migrations

    versions.each do |version|
      description = nil
      executed_at = nil
      execution_time = nil

      if executed_migrations.has_migration? version
        executed_migration = executed_migrations.migration version
        execution_time = executed_migration.execution_time
        executed_at = executed_migration.executed_at.try &.to_s("%F %T")
      end

      if available_migrations.has_migration? version
        description = available_migrations.migration(version).migration_class.new(@connection).description
      end

      status = if executed_migrations.has_migration?(version) && available_migrations.has_migration?(version)
                 "<info>migrated</info>"
               elsif executed_migrations.has_migration? version
                 "<error>migrated, not available</error>"
               else
                 "<comment>not migrated</comment>"
               end

      # Whole seconds are printed without a fraction, e.g. `2s`, and other times with up to 14 significant digits, e.g. `1.5s`.
      table.add_row(
        version.to_s,
        status,
        executed_at.to_s,
        execution_time ? "#{"%.14g" % execution_time.total_seconds}s" : "",
        description,
      )
    end

    table.render
  end

  # Renders a table of the configuration, the current, previous, next and latest versions, and the number of executed, available and new migrations.
  def show_migrations_info(output : ACON::Output::Interface) : Nil
    executed_migrations = @metadata_storage.executed_migrations
    available_migrations = @migration_plan_calculator.migrations
    new_migrations = @status_calculator.new_migrations
    executed_unavailable_migrations = @status_calculator.executed_unavailable_migrations

    table = ACON::Helper::Table.new output
    table.headers([[ACON::Helper::Table::Cell.new("Configuration", colspan: 3)] of ACON::Helper::Table::CellType])

    data_group = {
      "Storage" => {
        "Type"        => AORM::Migrations::Metadata::Storage::TableMetadataStorageConfiguration.name,
        "Table Name"  => @storage_configuration.table_name,
        "Column Name" => @storage_configuration.version_column_name,
      },
      "Database" => {
        "Driver" => @connection.driver.class.name,
      },
      "Versions" => {
        "Previous" => self.formatted_version_alias("prev"),
        "Current"  => self.formatted_version_alias("current"),
        "Next"     => self.formatted_version_alias("next"),
        "Latest"   => self.formatted_version_alias("latest"),
      },
      "Migrations" => {
        "Executed"             => executed_migrations.size.to_s,
        "Executed Unavailable" => executed_unavailable_migrations.size > 0 ? "<error>#{executed_unavailable_migrations.size}</error>" : "0",
        "Available"            => available_migrations.size.to_s,
        "New"                  => new_migrations.size > 0 ? "<question>#{new_migrations.size}</question>" : "0",
      },
      "Migration Namespaces" => {
        @configuration.namespace => @configuration.directory,
      },
    }

    data_group.each_with_index do |(group, data_values), idx|
      table.add_row ACON::Helper::Table::Separator.new(colspan: 3) unless idx.zero?

      data_values.each_with_index do |(key, value), row_idx|
        if row_idx.zero?
          table.add_row ACON::Helper::Table::Cell.new("<info>#{group}</info>", rowspan: data_values.size), key, value
        else
          table.add_row key, value
        end
      end
    end

    table.render
  end

  private def formatted_version_alias(version_alias : String) : String
    version = begin
      @alias_resolver.resolve_version_alias version_alias
    rescue ::Exception
      nil
    end

    if version.nil?
      return "Already at latest version" if version_alias == "next"
      return "Already at first version" if version_alias == "prev"
    end

    return "<comment>0</comment>" if version.to_s == "0"

    "<comment>#{version} </comment>"
  end
end
