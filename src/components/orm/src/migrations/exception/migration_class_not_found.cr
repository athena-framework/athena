# Raised when no migration has the requested version.
class Athena::ORM::Migrations::Exception::MigrationClassNotFound < RuntimeError
  include Athena::ORM::Migrations::Exception

  def initialize(migration_class : String)
    super "Migration class \"#{migration_class}\" was not found?"
  end
end
