# Raised when a version isn't in a list of available migrations.
class Athena::ORM::Migrations::Exception::MigrationNotAvailable < RuntimeError
  include Athena::ORM::Migrations::Exception

  def initialize(version : AORM::Migrations::Version::Version)
    super "The migration #{version} is not available"
  end
end
