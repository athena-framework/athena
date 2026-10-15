# Raised when there are no migrations left to execute, such as when resolving the `next` alias with every migration executed.
class Athena::ORM::Migrations::Exception::NoMigrationsToExecute < RuntimeError
  include Athena::ORM::Migrations::Exception

  def initialize(cause : ::Exception? = nil)
    super "Could not find any migrations to execute.", cause
  end
end
