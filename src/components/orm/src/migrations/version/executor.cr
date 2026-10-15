# Executes a single migration, and records it in the metadata storage.
#
# Each execution runs in a transaction if the migration is `AORM::Migrations::AbstractMigration#transactional?`, which is rolled back if the migration fails or is skipped.
class Athena::ORM::Migrations::Version::Executor
  # Returns the SQL of the migration being executed, and of the metadata storage during a dry run.
  getter sql : Array(AORM::Migrations::Query::Query) = [] of AORM::Migrations::Query::Query

  def initialize(
    @metadata_storage : AORM::Migrations::Metadata::Storage::Interface,
    @connection : AORM::Connection,
  ); end

  # Adds *query* to the SQL of the migration being executed.
  def add_sql(query : AORM::Migrations::Query::Query) : Nil
    @sql << query
  end

  # Executes the migration of *plan* in its direction, and returns the result.
  #
  # A skipped migration, see `AORM::Migrations::AbstractMigration#skip_if`, returns a skipped result.
  # Re-raises anything else the migration raises, after rolling back its transaction.
  def execute(plan : AORM::Migrations::Metadata::MigrationPlan, configuration : AORM::Migrations::MigratorConfiguration) : AORM::Migrations::Version::ExecutionResult
    result = AORM::Migrations::Version::ExecutionResult.new plan.version, plan.direction, Time.utc
    migration = plan.migration_class.new @connection

    self.start_migration migration

    begin
      self.execute_migration plan, migration, result, configuration

      result.sql = @sql
    rescue ex : AORM::Migrations::Exception::SkipMigration
      result.skipped = true

      self.migration_end ex, plan, migration, result
    rescue ex : ::Exception
      result.set_error true, ex

      self.migration_end ex, plan, migration, result

      raise ex
    end

    result
  end

  private def start_migration(migration : AORM::Migrations::AbstractMigration) : Nil
    @sql = [] of AORM::Migrations::Query::Query

    return unless migration.transactional?

    @connection.begin_transaction
  end

  # ameba:disable Metrics/CyclomaticComplexity
  private def execute_migration(
    plan : AORM::Migrations::Metadata::MigrationPlan,
    migration : AORM::Migrations::AbstractMigration,
    result : AORM::Migrations::Version::ExecutionResult,
    configuration : AORM::Migrations::MigratorConfiguration,
  ) : Nil
    direction = plan.direction

    result.time = time = Time.measure do
      result.state = :pre
      direction.up? ? migration.pre_up : migration.pre_down

      Log.info { self.migration_header plan, migration }

      result.state = :exec
      direction.up? ? migration.up : migration.down

      migration.sql.each { |query| self.add_sql query }

      migration.freeze

      if !@sql.empty?
        if configuration.dry_run?
          @sql.each { |query| self.output_sql_query query, configuration }
        else
          self.execute_result configuration
        end
      else
        Log.warn { "Migration #{plan.version} was executed but did not result in any SQL statements." }
      end

      result.state = :post
      direction.up? ? migration.post_up : migration.post_down
    end

    Log.info { "Migration #{plan.version} #{direction.up? ? "migrated" : "reverted"} (took #{time.total_milliseconds.round.to_i}ms)" }

    if !configuration.dry_run?
      @metadata_storage.complete result
    elsif (metadata_storage = @metadata_storage).responds_to? :sql
      metadata_storage.sql(result).each { |query| self.add_sql query }
    end

    if migration.transactional? && @connection.transaction_active?
      @connection.commit
    end

    plan.mark_as_executed result
    result.state = :none
  end

  private def migration_header(plan : AORM::Migrations::Metadata::MigrationPlan, migration : AORM::Migrations::AbstractMigration) : String
    version_info = plan.version.to_s
    description = migration.description

    version_info += " (#{description})" unless description.empty?

    plan.direction.up? ? "++ migrating #{version_info}" : "++ reverting #{version_info}"
  end

  private def migration_end(
    ex : ::Exception,
    plan : AORM::Migrations::Metadata::MigrationPlan,
    migration : AORM::Migrations::AbstractMigration,
    result : AORM::Migrations::Version::ExecutionResult,
  ) : Nil
    if migration.transactional? && @connection.transaction_active?
      @connection.rollback
    end

    plan.mark_as_executed result

    self.log_result ex, result, plan
  end

  private def log_result(ex : ::Exception, result : AORM::Migrations::Version::ExecutionResult, plan : AORM::Migrations::Metadata::MigrationPlan) : Nil
    if result.skipped?
      Log.notice { %(Migration #{plan.version} skipped during #{self.execution_state_as_string result.state}. Reason: "#{ex.message}") }
    elsif result.error?
      Log.error { %(Migration #{plan.version} failed during #{self.execution_state_as_string result.state}. Error: "#{ex.message}") }
    end
  end

  private def execute_result(configuration : AORM::Migrations::MigratorConfiguration) : Nil
    @sql.each do |query|
      self.output_sql_query query, configuration

      elapsed = Time.measure do
        # TODO: Statements returning rows, such as MySQL's `REPAIR TABLE`, can't be executed on MySQL and MariaDB, whose driver shard requires knowing beforehand whether a statement returns rows.
        @connection.execute_statement query.statement, query.parameters, query.types
      end

      next unless configuration.time_all_queries?

      Log.notice { "Query took #{elapsed.total_milliseconds.round.to_i}ms" }
    end
  end

  private def output_sql_query(query : AORM::Migrations::Query::Query, configuration : AORM::Migrations::MigratorConfiguration) : Nil
    message = "#{query.statement} #{self.format_parameters query}"

    if configuration.time_all_queries?
      Log.notice { message }
    else
      Log.debug { message }
    end
  end

  # Returns the parameters of *query* as they're bound, each converted through its type, e.g. `with parameters ([1], [2026-10-14 12:30:00])`.
  private def format_parameters(query : AORM::Migrations::Query::Query) : String
    return "" if query.parameters.empty?

    formatted_parameters = query.parameters.map_with_index do |value, idx|
      "[#{@connection.convert_to_database_value value, query.types[idx]?}]"
    end

    "with parameters (#{formatted_parameters.join ", "})"
  end

  private def execution_state_as_string(state : AORM::Migrations::Version::State) : String
    case state
    in .pre?  then "Pre-Checks"
    in .post? then "Post-Checks"
    in .exec? then "Execution"
    in .none? then "No State"
    end
  end
end
