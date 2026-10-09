# Value object standing in for any field type outside the scalars a driver can bind directly.
record CustomIdObject, id : String do
  def to_s(io : IO) : Nil
    io << @id
  end
end

# Converts a `CustomIdObject` to and from the string identifier it wraps.
struct CustomIdObjectType < AORM::Types::Type
  NAME = "CustomIdObject"

  def sql_declaration(column : AORM::Schema::Column, platform : AORM::Platforms::Platform) : String
    platform.string_type_declaration_sql column
  end

  def to_db(value : _, platform : AORM::Platforms::Platform)
    value.is_a?(CustomIdObject) ? value.id : value
  end

  def to_crystal_value(value : _, platform : AORM::Platforms::Platform) : CustomIdObject?
    case value
    when CustomIdObject then value
    when String         then CustomIdObject.new value
    end
  end

  def to_crystal_value(value : DB::ResultSet, platform : AORM::Platforms::Platform) : CustomIdObject?
    value.read(String?).try { |v| CustomIdObject.new v }
  end
end

AORM::Types::Type.add_type CustomIdObjectType::NAME, CustomIdObjectType.new
