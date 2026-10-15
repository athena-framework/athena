# Raised when a migrations command is given options that can't be used together, or is missing a required one.
class Athena::ORM::Migrations::Exception::InvalidOptionUsage < ArgumentError
  include Athena::ORM::Migrations::Exception
end
