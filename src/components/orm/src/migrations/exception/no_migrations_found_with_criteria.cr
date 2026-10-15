# Raised when no migration matches the requested criteria, such as the first migration of an empty list.
class Athena::ORM::Migrations::Exception::NoMigrationsFoundWithCriteria < RuntimeError
  include Athena::ORM::Migrations::Exception

  def initialize(criteria : String? = nil)
    super criteria ? "Could not find any migrations matching your criteria (#{criteria})." : "Could not find any migrations matching your criteria."
  end
end
