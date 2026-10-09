require "./type"

# Holds `Bytes`, stored in a fixed or variable-length binary column, such as `BINARY` or `VARBINARY`.
#
# Use `AORM::Types::Blob`, the default for `Bytes` properties, for binary data without a known maximum length.
struct Athena::ORM::Types::Binary < Athena::ORM::Types::Type
  # :inherit:
  def sql_declaration(column : Schema::Column, platform : AORM::Platforms::Platform) : ::String
    platform.binary_type_declaration_sql column
  end

  # :inherit:
  def to_crystal_value(value : _, platform : Platforms::Platform) : Bytes?
    case value
    when Nil, Bytes then value
    when ::String   then value.to_slice
    else                 raise "Binary cannot accept #{value.class}"
    end
  end

  # :inherit:
  def to_crystal_value(value : DB::ResultSet, platform : Platforms::Platform) : Bytes?
    self.to_crystal_value value.read, platform
  end
end
