require "../spec_helper"

struct TypedFieldMapperTest < ASPEC::TestCase
  def test_maps_crystal_types_to_their_default_column_types : Nil
    type_of(AORM::Mapping::TypedFieldMapper.new, "Int64").should eq "bigint"
  end

  def test_custom_mappings_extend_the_defaults : Nil
    mapper = AORM::Mapping::TypedFieldMapper.new({"Char" => "string"})

    type_of(mapper, "Char").should eq "string"
    type_of(mapper, "Int64").should eq "bigint"
  end

  def test_custom_mappings_override_the_defaults : Nil
    type_of(AORM::Mapping::TypedFieldMapper.new({"Int64" => "integer"}), "Int64").should eq "integer"
  end

  def test_an_explicit_type_is_kept : Nil
    mapping = AORM::Mapping::Driver::ColumnMapping.new field_name: "value", type: "text"
    info = AORM::Mapping::Class::FieldInfo.new name: "value", type_name: "String"

    AORM::Mapping::TypedFieldMapper.new.validate_and_complete(mapping, info).type.should eq "text"
  end

  private def type_of(mapper : AORM::Mapping::TypedFieldMapper, type_name : String) : String?
    mapping = AORM::Mapping::Driver::ColumnMapping.new field_name: "value"
    info = AORM::Mapping::Class::FieldInfo.new name: "value", type_name: type_name

    mapper.validate_and_complete(mapping, info).type
  end
end
