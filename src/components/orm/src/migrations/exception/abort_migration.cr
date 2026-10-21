require "./control_exception"

# Raised by `AORM::Migrations::AbstractMigration#abort_if` to stop executing a migration, failing it.
class Athena::ORM::Migrations::Exception::AbortMigration < RuntimeError
  include Athena::ORM::Migrations::Exception
  include Athena::ORM::Migrations::Exception::ControlException
end
