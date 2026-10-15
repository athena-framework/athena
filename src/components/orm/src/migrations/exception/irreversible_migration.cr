# Raised when reverting a migration that can't be reverted, see `AORM::Migrations::AbstractMigration#raise_irreversible_migration_exception`.
class Athena::ORM::Migrations::Exception::IrreversibleMigration < RuntimeError
  include Athena::ORM::Migrations::Exception
end
