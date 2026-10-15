# The outcome of executing a migration.
class Athena::ORM::Migrations::Version::ExecutionResult
  # Returns the version of the executed migration.
  getter version : AORM::Migrations::Version

  # Returns whether the migration was applied or reverted.
  getter direction : AORM::Migrations::Version::Direction

  # The time the migration was executed at.
  property executed_at : Time?

  # The SQL the migration executed.
  property sql : Array(AORM::Migrations::Query) = [] of AORM::Migrations::Query

  # How long executing the migration took.
  property time : Time::Span? = nil

  # Whether the migration was skipped, see `AORM::Migrations::AbstractMigration#skip_if`.
  property? skipped : Bool = false

  # Returns the exception that failed the migration, if any.
  getter exception : ::Exception? = nil

  @error : Bool = false

  # The stage the migration's execution is in, or was in when it was skipped or failed.
  property state : AORM::Migrations::Version::State = :none

  def initialize(
    @version : AORM::Migrations::Version,
    @direction : AORM::Migrations::Version::Direction = :up,
    @executed_at : Time? = nil,
  ); end

  # Returns `true` if the migration executed any SQL.
  def has_sql? : Bool
    !@sql.empty?
  end

  # Returns `true` if the migration failed.
  def error? : Bool
    @error
  end

  # Sets whether the migration failed, with the *exception* that failed it.
  def set_error(error : Bool, exception : ::Exception? = nil) : Nil
    @error = error
    @exception = exception
  end
end
