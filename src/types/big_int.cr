require "./type"

# Holds `Int64` values, stored in a `BIGINT` column.
#
# `Int64` properties, and enums based on `Int64`, `UInt32` or `UInt64`, are mapped to this type by default.
struct Athena::ORM::Types::BigInt < Athena::ORM::Types::Type
  # :inherit:
  def sql_declaration(column : Schema::Column, platform : AORM::Platforms::Platform) : ::String
    platform.big_int_type_declaration_sql column
  end

  # :inherit:
  def to_db(value : _, platform : AORM::Platforms::Platform)
    value
  end

  # :inherit:
  def to_crystal_value(value : _, platform : Platforms::Platform) : Int64?
    case value
    when Nil                      then nil
    when ::Int, ::Float, ::String then value.to_i64
    else                               raise "BigInt cannot accept #{value.class}"
    end
  end

  # :inherit:
  def to_crystal_value(value : DB::ResultSet, platform : Platforms::Platform) : Int64?
    value.read Int64?
  end
end
