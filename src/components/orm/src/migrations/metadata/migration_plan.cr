# A migration planned to be executed in a given direction.
class Athena::ORM::Migrations::Metadata::MigrationPlan
  # Returns the version of the migration.
  getter version : AORM::Migrations::Version::Version

  # Returns the type of the migration.
  getter migration_class : AORM::Migrations::AbstractMigration.class

  # Returns whether the migration is to be applied or reverted.
  getter direction : AORM::Migrations::Version::Direction

  # Returns the result of executing the migration, or `nil` if it hasn't been executed yet.
  getter result : AORM::Migrations::Version::ExecutionResult? = nil

  def initialize(
    @version : AORM::Migrations::Version::Version,
    @migration_class : AORM::Migrations::AbstractMigration.class,
    @direction : AORM::Migrations::Version::Direction,
  ); end

  # Sets the *result* of executing the migration.
  #
  # Raises `AORM::Migrations::Exception::PlanAlreadyExecuted` if it was already set.
  def mark_as_executed(result : AORM::Migrations::Version::ExecutionResult) : Nil
    raise AORM::Migrations::Exception::PlanAlreadyExecuted.new unless @result.nil?

    @result = result
  end
end
