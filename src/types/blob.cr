require "./type"

# Holds `Bytes`, stored in a binary large object column, such as `BLOB` or `BYTEA`.
#
# `Bytes` properties are mapped to this type by default.
struct Athena::ORM::Types::Blob < Athena::ORM::Types::Type
  # :inherit:
  def sql_declaration(column : Schema::Column, platform : AORM::Platforms::Platform) : ::String
    platform.blob_type_declaration_sql column
  end

  # :inherit:
  def to_crystal_value(value : _, platform : Platforms::Platform) : Bytes?
    case value
    when Nil, Bytes then value
    when ::String   then value.to_slice
    else                 raise "Blob cannot accept #{value.class}"
    end
  end

  # :inherit:
  def to_crystal_value(value : DB::ResultSet, platform : Platforms::Platform) : Bytes?
    self.to_crystal_value value.read, platform
  end
end
