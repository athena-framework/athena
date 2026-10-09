require "uuid"
require "./type"

# Holds `UUID` values, stored in a `UUID` column on Postgres, and as their 36 character string form elsewhere.
#
# `UUID` properties are mapped to this type by default.
#
# NOTE: `AORM::EntityManager#find` takes a `UUID` identifier as its string form.
struct Athena::ORM::Types::Guid < Athena::ORM::Types::Type
  # :inherit:
  def sql_declaration(column : Schema::Column, platform : AORM::Platforms::Platform) : ::String
    platform.guid_type_declaration_sql column
  end

  # :inherit:
  #
  # Converts a `UUID` into its string form, since drivers can't bind `UUID` but every database accepts its string form.
  def to_db(value : _, platform : AORM::Platforms::Platform)
    value.is_a?(UUID) ? value.to_s : value
  end

  # :inherit:
  def to_crystal_value(value : _, platform : Platforms::Platform) : UUID?
    case value
    when Nil, UUID then value
    when ::String  then UUID.new value
    else                raise "Guid cannot accept #{value.class}"
    end
  end

  # :inherit:
  def to_crystal_value(value : DB::ResultSet, platform : Platforms::Platform) : UUID?
    self.to_crystal_value value.read, platform
  end
end
