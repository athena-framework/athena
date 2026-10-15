# Raised when the result of a `AORM::Migrations::Metadata::MigrationPlan` is set more than once.
class Athena::ORM::Migrations::Exception::PlanAlreadyExecuted < RuntimeError
  include Athena::ORM::Migrations::Exception

  def initialize
    super "This plan was already marked as executed."
  end
end
