require "./type"

# Holds decimal values as strings, so no precision is lost.
# Map a `BigDecimal` field with `Types::Number` instead to work with the values numerically.
#
# Values are stored in a `NUMERIC`/`DECIMAL` column.
# Fields are only mapped to this type explicitly, e.g. `@[AORMA::Column(type: "decimal", precision: 10, scale: 2)]` on a `String` property.
#
# WARNING: MySQL and MariaDB read `DECIMAL` columns as `Float64`, so on those databases values are limited to `Float64` precision and lose their scale, e.g. `"12.3400"` reads back as `"12.34"`.
# SQLite stores them with `REAL` affinity, with the same limitation.
struct Athena::ORM::Types::Decimal < Athena::ORM::Types::Type
  # :inherit:
  def sql_declaration(column : Schema::Column, platform : AORM::Platforms::Platform) : ::String
    platform.decimal_type_declaration_sql column
  end

  # :inherit:
  def to_crystal_value(value : _, platform : Platforms::Platform) : ::String?
    case value
    when Nil, ::String         then value
    when ::Bool, ::Time, Bytes then raise "Decimal cannot accept #{value.class}"
    else
      # SQLite can return a decimal column as a float or integer, and Postgres as a `PG::Numeric`.
      value.to_s
    end
  end

  # :inherit:
  def to_crystal_value(value : DB::ResultSet, platform : Platforms::Platform) : ::String?
    self.to_crystal_value value.read, platform
  end
end
