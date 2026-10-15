# A migration that has been executed, as recorded by the metadata storage.
struct Athena::ORM::Migrations::Metadata::ExecutedMigration
  # Returns the version of the migration.
  getter version : AORM::Migrations::Version

  # Returns the time the migration was executed at, if it was recorded.
  getter executed_at : Time?

  # Returns how long executing the migration took, if it was recorded.
  getter execution_time : Time::Span?

  def initialize(
    @version : AORM::Migrations::Version,
    @executed_at : Time? = nil,
    @execution_time : Time::Span? = nil,
  ); end
end
