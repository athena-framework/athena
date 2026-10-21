# Configures where migrations are generated, and how.
struct Athena::ORM::Migrations::Configuration
  # Returns the namespace of the application's migrations, e.g. `App::Migrations`.
  getter namespace : String

  # Returns the directory generated migrations are written to, e.g. `src/migrations`.
  getter directory : String

  # Whether generated migrations run in a transaction, see `AORM::Migrations::AbstractMigration#transactional?`.
  getter? transactional : Bool

  def initialize(
    @namespace : String,
    @directory : String,
    @transactional : Bool = true,
  ); end
end
