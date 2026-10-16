# Parent of the exceptions raised by entity persisters when building the SQL to load entities.
class Athena::ORM::Exception::Persister < RuntimeError
  include Athena::ORM::Exception
end
