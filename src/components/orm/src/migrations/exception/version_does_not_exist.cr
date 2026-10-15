# Raised when marking a migration as not executed that isn't recorded as executed.
class Athena::ORM::Migrations::Exception::VersionDoesNotExist < ArgumentError
  include Athena::ORM::Migrations::Exception

  def initialize(version : AORM::Migrations::Version)
    super %(The version "#{version}" does not exist in the version table.)
  end
end
