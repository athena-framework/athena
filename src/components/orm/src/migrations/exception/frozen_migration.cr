# Raised when SQL is added to a migration whose SQL has already been executed.
class Athena::ORM::Migrations::Exception::FrozenMigration < ::Exception
  include Athena::ORM::Migrations::Exception

  def initialize
    super "The migration is frozen and cannot be edited anymore."
  end
end
