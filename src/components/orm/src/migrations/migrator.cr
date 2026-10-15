# Executes the migrations of a plan, one after the other, see `AORM::Migrations::Version::Executor`.
class Athena::ORM::Migrations::Migrator
  def initialize(
    @executor : AORM::Migrations::Version::Executor,
  ); end

  # Executes the migrations of *migrations_plan*, and returns the SQL each executed, keyed by its version.
  # Stops at the first migration that fails, re-raising what it raised.
  def migrate(migrations_plan : AORM::Migrations::Metadata::MigrationPlanList, configuration : AORM::Migrations::MigratorConfiguration) : Hash(AORM::Migrations::Version::Version, Array(AORM::Migrations::Query::Query))
    sql = Hash(AORM::Migrations::Version::Version, Array(AORM::Migrations::Query::Query)).new

    if migrations_plan.size.zero?
      Log.notice { "No migrations to execute." }

      return sql
    end

    elapsed = Time.measure do
      migrations_plan.items.each do |plan|
        sql[plan.version] = @executor.execute(plan, configuration).sql
      end
    end

    Log.notice do
      "finished in #{elapsed.total_milliseconds.round.to_i}ms, #{migrations_plan.size} migrations executed, #{sql.sum(&.[1].size)} sql queries"
    end

    sql
  end
end
