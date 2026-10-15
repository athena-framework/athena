# Resolves the version a command is given, which may be an alias, to the version of a migration.
#
# | Alias | Resolves to |
# | ----- | ----------- |
# | `first` or `0` | `0`, the version before the first migration |
# | `current` | The last executed migration, or `0` if none were |
# | `prev` | The executed migration before the last one, or `0` if there isn't one |
# | `next` | The first migration that hasn't been executed |
# | `latest` | The last available migration, or `current` if there are none |
# | `current-N` | The *N*th executed migration before the last one |
# | `current+N` | The *N*th migration after the last executed one that hasn't been executed |
#
# Any other value is resolved as the version itself, i.e. a migration's fully qualified type name.
class Athena::ORM::Migrations::Version::AliasResolver
  private ALIAS_FIRST   = "first"
  private ALIAS_CURRENT = "current"
  private ALIAS_PREV    = "prev"
  private ALIAS_NEXT    = "next"
  private ALIAS_LATEST  = "latest"

  def initialize(
    @migration_plan_calculator : AORM::Migrations::Version::MigrationPlanCalculator,
    @metadata_storage : AORM::Migrations::Metadata::Storage::Interface,
    @migration_status_calculator : AORM::Migrations::Version::MigrationStatusCalculator,
  ); end

  # Returns the version *version_alias* resolves to.
  #
  # Raises `AORM::Migrations::Exception::UnknownMigrationVersion` if it doesn't resolve to one, and `AORM::Migrations::Exception::NoMigrationsToExecute` for `next` if every migration has been executed.
  #
  # ameba:disable Metrics/CyclomaticComplexity
  def resolve_version_alias(version_alias : String) : AORM::Migrations::Version
    available_migrations = @migration_plan_calculator.migrations
    executed_migrations = @metadata_storage.executed_migrations

    case version_alias
    when ALIAS_FIRST, "0"
      return AORM::Migrations::Version.new "0"
    when ALIAS_CURRENT
      begin
        return executed_migrations.last.version
      rescue AORM::Migrations::Exception::NoMigrationsFoundWithCriteria
        return AORM::Migrations::Version.new "0"
      end
    when ALIAS_PREV
      begin
        return executed_migrations.last(-1).version
      rescue AORM::Migrations::Exception::NoMigrationsFoundWithCriteria
        return AORM::Migrations::Version.new "0"
      end
    when ALIAS_NEXT
      begin
        return @migration_status_calculator.new_migrations.first.version
      rescue ex : AORM::Migrations::Exception::NoMigrationsFoundWithCriteria
        raise AORM::Migrations::Exception::NoMigrationsToExecute.new ex
      end
    when ALIAS_LATEST
      begin
        return available_migrations.last.version
      rescue AORM::Migrations::Exception::NoMigrationsFoundWithCriteria
        return self.resolve_version_alias ALIAS_CURRENT
      end
    else
      version = AORM::Migrations::Version.new version_alias

      return available_migrations.migration(version).version if available_migrations.has_migration? version

      if version_alias.starts_with? ALIAS_CURRENT
        offset = version_alias[ALIAS_CURRENT.size..].to_i? || 0

        if offset > 0
          return @migration_status_calculator.new_migrations.first(offset - 1).version
        end

        return executed_migrations.last(offset).version
      end
    end

    raise AORM::Migrations::Exception::UnknownMigrationVersion.new version_alias
  end
end
