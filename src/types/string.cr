require "./type"

# Holds `String` values, stored in a `VARCHAR` column.
#
# `String` properties are mapped to this type by default.
# It's also registered as `text`.
struct Athena::ORM::Types::String < Athena::ORM::Types::Type
  # :inherit:
  def sql_declaration(column : Schema::Column, platform : AORM::Platforms::Platform) : ::String
    platform.string_type_declaration_sql column
  end

  # :inherit:
  def to_crystal_value(value : _, platform : Platforms::Platform) : ::String?
    case value
    when Nil      then nil
    when ::String then value
    else               value.to_s
    end
  end

  # :inherit:
  def to_crystal_value(value : DB::ResultSet, platform : Platforms::Platform) : ::String?
    value.read ::String?
  end
end
