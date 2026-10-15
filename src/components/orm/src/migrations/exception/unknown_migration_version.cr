# Raised when a version or alias doesn't resolve to a migration, see `AORM::Migrations::Version::AliasResolver`.
class Athena::ORM::Migrations::Exception::UnknownMigrationVersion < RuntimeError
  include Athena::ORM::Migrations::Exception

  def initialize(version : String)
    super "Could not find migration version #{version}"
  end
end
