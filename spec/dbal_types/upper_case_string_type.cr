# Converts values in SQL rather than in Crystal, to observe which direction a statement applies.
struct UpperCaseStringType < AORM::Types::Type
  NAME = "upper_case_string"

  def sql_declaration(column : AORM::Schema::Column, platform : AORM::Platforms::Platform) : String
    platform.string_type_declaration_sql column
  end

  def to_db_sql(sql_expression : String, platform : AORM::Platforms::Platform) : String
    "UPPER(#{sql_expression})"
  end

  def from_db_sql(sql_expression : String, platform : AORM::Platforms::Platform) : String
    "LOWER(#{sql_expression})"
  end

  def to_crystal_value(value : _, platform : AORM::Platforms::Platform) : String?
    value.as?(String)
  end

  def to_crystal_value(value : DB::ResultSet, platform : AORM::Platforms::Platform) : String?
    value.read String?
  end
end

AORM::Types::Type.add_type UpperCaseStringType::NAME, UpperCaseStringType.new
