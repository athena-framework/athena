# Raised when marking a migration as executed that's already recorded as executed.
class Athena::ORM::Migrations::Exception::VersionAlreadyExists < ArgumentError
  include Athena::ORM::Migrations::Exception

  def initialize(version : AORM::Migrations::Version)
    super %(The version "#{version}" already exists in the version table.)
  end
end
