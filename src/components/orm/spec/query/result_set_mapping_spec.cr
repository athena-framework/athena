require "../spec_helper"

struct ResultSetMappingTest < ASPEC::TestCase
  def test_add_entity_result : Nil
    rsm = AORM::Query::ResultSetMapping.new

    rsm.add_entity_result(CmsUser, "u")

    rsm.alias_map.has_key?("u").should be_true
    rsm.alias_map["u"].should eq CmsUser
    rsm.mixed?.should be_false
  end

  def test_add_entity_result_with_result_alias_sets_mixed : Nil
    rsm = AORM::Query::ResultSetMapping.new

    rsm.add_entity_result(CmsUser, "u", "user_alias")

    rsm.mixed?.should be_true
  end

  def test_add_field_result : Nil
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result(CmsUser, "u")

    rsm.add_field_result("u", "id0", "id")
    rsm.add_field_result("u", "username1", "username")

    rsm.field_mappings["id0"].should eq "id"
    rsm.field_mappings["username1"].should eq "username"

    rsm.column_owner_map["id0"].should eq "u"
    rsm.column_owner_map["username1"].should eq "u"

    rsm.columns.size.should eq 2
    rsm.columns[0].column_name.should eq "id0"
    rsm.columns[0].kind.field?.should be_true
    rsm.columns[1].column_name.should eq "username1"
    rsm.columns[1].kind.field?.should be_true
  end

  def test_add_scalar_result : Nil
    rsm = AORM::Query::ResultSetMapping.new

    rsm.add_scalar_result("cnt", "count", "integer")

    rsm.scalar_mappings["cnt"].should eq "count"
    rsm.type_mappings["cnt"].should eq "integer"

    rsm.columns.size.should eq 1
    rsm.columns[0].column_name.should eq "cnt"
    rsm.columns[0].kind.scalar?.should be_true
  end

  def test_add_scalar_result_sets_mixed_when_fields_exist : Nil
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result(CmsUser, "u")
    rsm.add_field_result("u", "id0", "id")

    rsm.mixed?.should be_false

    rsm.add_scalar_result("cnt", "count")

    rsm.mixed?.should be_true
  end

  def test_add_meta_result : Nil
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result(CmsUser, "u")

    rsm.add_meta_result("u", "user_type", "discriminator", false, "string")

    rsm.meta_mappings["user_type"].should eq "discriminator"
    rsm.column_owner_map["user_type"].should eq "u"
    rsm.type_mappings["user_type"].should eq "string"

    rsm.columns.size.should eq 1
    rsm.columns[0].column_name.should eq "user_type"
    rsm.columns[0].kind.meta?.should be_true
  end

  def test_add_meta_result_as_identifier : Nil
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result(CmsUser, "u")

    rsm.add_meta_result("u", "fk_id", "foreign_id", true, "integer")

    rsm.is_identifier_column["u"]["fk_id"].should be_true
  end

  def test_add_joined_entity_result : Nil
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result(CmsUser, "u")
    rsm.add_joined_entity_result(CmsGroup, "g", "u", "groups")

    rsm.alias_map["g"].should eq CmsGroup
    rsm.parent_alias_map["g"].should eq "u"
    rsm.relation_map["g"].should eq "groups"
  end

  def test_root_alias : Nil
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result(CmsUser, "u")
    rsm.add_joined_entity_result(CmsGroup, "g", "u", "groups")

    rsm.root_alias.should eq "u"
  end

  def test_joined_aliases : Nil
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result(CmsUser, "u")
    rsm.add_joined_entity_result(CmsGroup, "g", "u", "groups")

    rsm.joined_aliases.should eq ["g"]
  end

  def test_has_parent_alias : Nil
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result(CmsUser, "u")
    rsm.add_joined_entity_result(CmsGroup, "g", "u", "groups")

    rsm.has_parent_alias?("u").should be_false
    rsm.has_parent_alias?("g").should be_true
  end

  def test_class_metadata : Nil
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result(CmsUser, "u")

    rsm.class_metadata("u").should eq CmsUser
  end

  def test_field_name : Nil
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result(CmsUser, "u")
    rsm.add_field_result("u", "col_id", "id")

    rsm.field_name("col_id").should eq "id"
  end

  def test_entity_alias : Nil
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result(CmsUser, "u")
    rsm.add_field_result("u", "col_id", "id")

    rsm.entity_alias("col_id").should eq "u"
  end

  def test_field_result? : Nil
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result(CmsUser, "u")
    rsm.add_field_result("u", "col_id", "id")

    rsm.field_result?("col_id").should be_true
    rsm.field_result?("nonexistent").should be_false
  end

  def test_scalar_result? : Nil
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_scalar_result("cnt", "count")

    rsm.scalar_result?("cnt").should be_true
    rsm.scalar_result?("nonexistent").should be_false
  end

  def test_entity_result_count : Nil
    rsm = AORM::Query::ResultSetMapping.new

    rsm.entity_result_count.should eq 0

    rsm.add_entity_result(CmsUser, "u")
    rsm.entity_result_count.should eq 1

    rsm.add_joined_entity_result(CmsGroup, "g", "u", "groups")
    rsm.entity_result_count.should eq 2
  end

  def test_add_index_by : Nil
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result(CmsUser, "u")
    rsm.add_field_result("u", "col_id", "id")

    rsm.add_index_by("u", "id")

    rsm.index_by_map["u"].should eq "col_id"
  end

  def test_add_index_by_column : Nil
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result(CmsUser, "u")
    rsm.add_field_result("u", "col_id", "id")

    rsm.add_index_by_column("u", "col_id")

    rsm.index_by_map["u"].should eq "col_id"
  end

  def test_fluent_interface : Nil
    rsm = AORM::Query::ResultSetMapping.new

    result = rsm
      .add_entity_result(CmsUser, "u")
      .add_field_result("u", "id0", "id")
      .add_field_result("u", "username1", "username")

    result.should be rsm
    rsm.columns.size.should eq 2
  end

  def test_columns_preserve_add_order : Nil
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result(CmsUser, "u")

    rsm.add_field_result("u", "id0", "id")
    rsm.add_scalar_result("total", "total_count")
    rsm.add_field_result("u", "username1", "username")
    rsm.add_meta_result("u", "dtype", "discriminator")

    rsm.columns.size.should eq 4
    rsm.columns[0].column_name.should eq "id0"
    rsm.columns[0].kind.field?.should be_true
    rsm.columns[1].column_name.should eq "total"
    rsm.columns[1].kind.scalar?.should be_true
    rsm.columns[2].column_name.should eq "username1"
    rsm.columns[2].kind.field?.should be_true
    rsm.columns[3].column_name.should eq "dtype"
    rsm.columns[3].kind.meta?.should be_true
  end

  def test_add_index_by_raises_for_an_unregistered_field : Nil
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result(CmsUser, "u")

    expect_raises(Exception, /not registered/) do
      rsm.add_index_by("u", "id")
    end
  end

  def test_has_column_alias_by_field_round_trip : Nil
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result(CmsUser, "u")
    rsm.add_field_result("u", "u__id", "id")

    rsm.has_column_alias_by_field?("u", "id").should be_true
    rsm.has_column_alias_by_field?("u", "missing").should be_false
    rsm.column_alias_by_field("u", "id").should eq "u__id"
  end
end
