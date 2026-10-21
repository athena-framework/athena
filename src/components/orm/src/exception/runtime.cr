# Represents an error that can only be detected while the program runs.
class Athena::ORM::Exception::Runtime < RuntimeError
  include Athena::ORM::Exception
end
