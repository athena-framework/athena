require "./control_exception"

# Raised by `AORM::Migrations::AbstractMigration#skip_if` to stop executing a migration without failing it.
class Athena::ORM::Migrations::Exception::SkipMigration < RuntimeError
  include Athena::ORM::Migrations::Exception
  include Athena::ORM::Migrations::Exception::ControlException
end
