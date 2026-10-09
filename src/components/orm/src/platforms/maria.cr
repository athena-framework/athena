require "./platform"

# Base platform for MariaDB.
#
# Database-generated identifiers are read back with `INSERT ... RETURNING`.
class Athena::ORM::Platforms::Maria < Athena::ORM::Platforms::AbstractMySQL
  # :inherit:
  def supports_returning? : Bool
    true
  end
end
