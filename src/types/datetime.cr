require "./type"

# Holds `Time` values, stored in a date and time column without a time zone, such as `TIMESTAMP` or `DATETIME`.
#
# `Time` properties are mapped to this type by default.
# Values are converted to UTC when written, and read back as UTC.
struct Athena::ORM::Types::Datetime < Athena::ORM::Types::Type
  # :inherit:
  def sql_declaration(column : Schema::Column, platform : AORM::Platforms::Platform) : ::String
    platform.date_time_type_declaration_sql column
  end

  # :inherit:
  #
  # Converts a `Time` into UTC.
  def to_db(value : _, platform : AORM::Platforms::Platform)
    # Columns hold UTC wall-clock time with no offset, and values are read back as UTC.
    value.is_a?(::Time) ? value.to_utc : value
  end

  # :inherit:
  def to_crystal_value(value : _, platform : Platforms::Platform) : ::Time?
    return value if value.is_a?(::Time?)

    raise "Datetime cannot accept #{value.class}" unless value.is_a? ::String

    ::Time.parse_utc value, platform.date_time_format_string
  end

  # :inherit:
  def to_crystal_value(value : DB::ResultSet, platform : Platforms::Platform) : ::Time?
    value.read ::Time?
  end
end
