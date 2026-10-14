# Raised when a version isn't in a list of executed migrations.
class Athena::ORM::Migrations::Exception::MigrationNotExecuted < RuntimeError
  include Athena::ORM::Migrations::Exception

  def initialize(version : String)
    super "The provided migration #{version} has not been executed"
  end
end
