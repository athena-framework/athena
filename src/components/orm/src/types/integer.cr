require "./type"

# Holds `Int32` values, stored in an `INTEGER` column.
#
# `Int32` properties, and enums whose base type fits in an `Int32`, are mapped to this type by default.
struct Athena::ORM::Types::Integer < Athena::ORM::Types::Type
  # :inherit:
  def sql_declaration(column : Schema::Column, platform : AORM::Platforms::Platform) : ::String
    platform.integer_type_declaration_sql column
  end

  # :inherit:
  def to_db(value : _, platform : AORM::Platforms::Platform)
    value
  end

  # :inherit:
  def to_crystal_value(value : _, platform : Platforms::Platform) : Int32?
    case value
    when Nil                      then nil
    when ::Int, ::String, ::Float then value.to_i32
    else                               raise AORM::Exception::ValueNotConvertible.new value.to_s, AORM::Types::INTEGER
    end
  rescue ex : ArgumentError | OverflowError
    raise AORM::Exception::ValueNotConvertible.new value.to_s, AORM::Types::INTEGER, cause: ex
  end

  # :inherit:
  def to_crystal_value(value : DB::ResultSet, platform : Platforms::Platform) : Int32?
    value.read Int32?
  end
end
