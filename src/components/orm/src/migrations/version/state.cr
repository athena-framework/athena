# The stage of executing a migration, used to report where it failed or was skipped.
enum Athena::ORM::Migrations::Version::State
  # Not executing.
  NONE

  # Running `AORM::Migrations::AbstractMigration#pre_up` or `#pre_down`.
  PRE

  # Running `AORM::Migrations::AbstractMigration#up` or `#down`, and executing its SQL.
  EXEC

  # Running `AORM::Migrations::AbstractMigration#post_up` or `#post_down`.
  POST
end
