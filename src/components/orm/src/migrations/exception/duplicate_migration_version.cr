# Raised when more than one migration has the same version.
class Athena::ORM::Migrations::Exception::DuplicateMigrationVersion < RuntimeError
  include Athena::ORM::Migrations::Exception

  def initialize(version : String, class_name : String)
    super "Migration version #{version} already registered with class #{class_name}"
  end
end
