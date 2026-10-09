require "../spec_helper"

# Fixtures for direct `Mapping::Class(T)` tests.
# Each entity has only the ivars its tests need; nothing is shared across describe-blocks.

@[AORMA::Entity]
class TypedFieldsFixture < AORM::Entity
  property id : Int64? = nil
  property name : String? = nil
  property flag : Bool? = nil
  property count : Int32? = nil
  property created : Time? = nil
end

@[AORMA::Entity]
class SinglePkFixture < AORM::Entity
  property id : Int64? = nil
  property label : String? = nil
end

@[AORMA::Entity]
class CompositePkFixture < AORM::Entity
  property id_a : Int64? = nil
  property id_b : Int64? = nil
end

@[AORMA::Entity]
class NoIdFixture < AORM::Entity
  property name : String? = nil
end

@[AORMA::Entity]
class AssocTarget < AORM::Entity
  property id : Int64? = nil
end

@[AORMA::Entity]
class AssocOwner < AORM::Entity
  property id : Int64? = nil
  property target : AssocTarget? = nil
  property lazy_target : AORM::Proxy(AssocTarget)? = nil
  property collection : AORM::Collection(AssocTarget) = AORM::ArrayCollection(AssocTarget).new
end

@[AORMA::Entity]
class InverseAssocOwner < AORM::Entity
  property id : Int64? = nil
  property collection : AORM::Collection(AssocTarget) = AORM::ArrayCollection(AssocTarget).new
end

@[AORMA::Entity]
class TableQuotingFixture < AORM::Entity
  property id : Int64? = nil
end

struct MappingClassTest < ASPEC::TestCase
  # ---- field type inference ----

  def test_field_type_inferred_from_int64_ivar : Nil
    metadata = AORM::Mapping::Class(TypedFieldsFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id")
    metadata.field_mappings["id"].type.should eq "bigint"
  end

  def test_field_type_inferred_from_int32_ivar : Nil
    metadata = AORM::Mapping::Class(TypedFieldsFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "count")
    metadata.field_mappings["count"].type.should eq "integer"
  end

  def test_field_type_inferred_from_string_ivar : Nil
    metadata = AORM::Mapping::Class(TypedFieldsFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "name")
    metadata.field_mappings["name"].type.should eq "string"
  end

  def test_field_type_inferred_from_bool_ivar : Nil
    metadata = AORM::Mapping::Class(TypedFieldsFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "flag")
    metadata.field_mappings["flag"].type.should eq "boolean"
  end

  def test_field_type_inferred_from_time_ivar : Nil
    metadata = AORM::Mapping::Class(TypedFieldsFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "created")
    metadata.field_mappings["created"].type.should eq "datetime"
  end

  def test_explicit_type_wins_over_inference : Nil
    metadata = AORM::Mapping::Class(TypedFieldsFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "name", type: "text")
    metadata.field_mappings["name"].type.should eq "text"
  end

  # ---- column name defaulting and quoting ----

  def test_column_name_defaults_to_field_name : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "label")
    metadata.field_mappings["label"].column_name.should eq "label"
    metadata.field_mappings["label"].quoted.should be_falsey
  end

  def test_column_name_explicit_overrides_default : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "label", column_name: "lbl")
    metadata.field_mappings["label"].column_name.should eq "lbl"
  end

  def test_backticked_column_name_strips_and_marks_quoted : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "label", column_name: "`label`")
    field = metadata.field_mappings["label"]
    field.column_name.should eq "label"
    field.quoted.should be_true
  end

  # ---- duplicate detection ----

  def test_duplicate_column_name_raises : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id", column_name: "shared")

    expect_raises Exception, /Duplicate column name 'shared'/ do
      metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "label", column_name: "shared")
    end
  end

  def test_duplicate_field_mapping_raises : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id", column_name: "col_a")

    expect_raises Exception, /Duplicate field mapping 'id'/ do
      metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id", column_name: "col_b")
    end
  end

  # ---- identifier handling ----

  def test_single_id_populates_identifier_set : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id", id: true)

    metadata.identifier.should eq Set{"id"}
    metadata.is_identifier_composite.should be_false
    metadata.single_identifier_field_name.should eq "id"
    metadata.single_identifier_column_name.should eq "id"
    metadata.is_identifier?("id").should be_true
    metadata.is_identifier?("label").should be_false
  end

  def test_two_ids_flip_composite_flag : Nil
    metadata = AORM::Mapping::Class(CompositePkFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id_a", id: true)
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id_b", id: true)

    metadata.is_identifier_composite.should be_true
    metadata.identifier.should eq Set{"id_a", "id_b"}
    metadata.is_identifier?("id_a").should be_true
    metadata.is_identifier?("id_b").should be_true
  end

  def test_single_identifier_field_name_raises_for_composite : Nil
    metadata = AORM::Mapping::Class(CompositePkFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id_a", id: true)
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id_b", id: true)

    expect_raises Exception, /single id not allowed on composite primary key/ do
      metadata.single_identifier_field_name
    end
  end

  def test_single_identifier_field_name_raises_when_no_id_defined : Nil
    metadata = AORM::Mapping::Class(NoIdFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "name")

    expect_raises Exception, /no ID defined/ do
      metadata.single_identifier_field_name
    end
  end

  def test_identifier_natural_and_identity : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new
    metadata.identifier_natural?.should be_true
    metadata.identifier_identity?.should be_false

    metadata.id_generator_type = :identity
    metadata.identifier_natural?.should be_false
    metadata.identifier_identity?.should be_true
  end

  # ---- identifier_values / set_identifier_values / assign_identifier ----

  def test_identifier_values_for_single_pk_returns_value : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id", id: true)

    entity = SinglePkFixture.new
    entity.id = 7_i64

    metadata.identifier_values(entity).should eq({"id" => 7_i64})
  end

  def test_identifier_values_returns_empty_when_id_nil : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id", id: true)

    entity = SinglePkFixture.new
    metadata.identifier_values(entity).should be_empty
  end

  def test_identifier_values_for_composite_returns_each_value : Nil
    metadata = AORM::Mapping::Class(CompositePkFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id_a", id: true)
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id_b", id: true)

    entity = CompositePkFixture.new
    entity.id_a = 1_i64
    entity.id_b = 2_i64

    metadata.identifier_values(entity).should eq({"id_a" => 1_i64, "id_b" => 2_i64})
  end

  # Like a single identifier without a value, composite identifier fields without a value are left out.
  def test_identifier_values_for_composite_omits_fields_without_a_value : Nil
    metadata = AORM::Mapping::Class(CompositePkFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id_a", id: true)
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id_b", id: true)

    entity = CompositePkFixture.new
    entity.id_a = 1_i64

    metadata.identifier_values(entity).should eq({"id_a" => 1_i64})
  end

  def test_set_identifier_values_writes_ivars : Nil
    metadata = AORM::Mapping::Class(CompositePkFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id_a", id: true)
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id_b", id: true)

    entity = CompositePkFixture.new
    metadata.set_identifier_values(entity, {"id_a" => 10_i64, "id_b" => 20_i64})
    entity.id_a.should eq 10_i64
    entity.id_b.should eq 20_i64
  end

  def test_assign_identifier_writes_matching_type : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id", id: true)

    entity = SinglePkFixture.new
    metadata.assign_identifier(entity, "id", 42_i64)
    entity.id.should eq 42_i64
  end

  def test_assign_identifier_raises_on_unknown_field : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new

    expect_raises Exception, /Field nope not found/ do
      metadata.assign_identifier(SinglePkFixture.new, "nope", 1_i64)
    end
  end

  def test_set_field_value_raises_on_type_mismatch : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new

    expect_raises Exception, "Type mismatch for 'label' on SinglePkFixture: got Int32" do
      metadata.set_field_value SinglePkFixture.new, "label", 1
    end
  end

  def test_create_column_value_raises_on_type_mismatch : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new

    expect_raises Exception, "Type mismatch for 'label' on SinglePkFixture: got Int32" do
      metadata.create_column_value "label", 1
    end
  end

  def test_field_access_raises_for_an_entity_of_another_class : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new

    expect_raises Exception, "BUG: entity type mismatch on Class(SinglePkFixture)#get_field_value: got CompositePkFixture" do
      metadata.get_field_value CompositePkFixture.new, "id"
    end
  end

  def test_assign_identifier_raises_on_type_mismatch : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new

    expect_raises Exception, /type mismatch/ do
      metadata.assign_identifier(SinglePkFixture.new, "id", "not-an-int")
    end
  end

  # ---- association mapping ----

  def test_one_to_one_owning_infers_target_from_property : Nil
    metadata = AORM::Mapping::Class(AssocOwner).new
    metadata.map_one_to_one AORM::Mapping::Driver::ColumnMapping.new(field_name: "target")

    assoc = metadata.association_mappings["target"]
    assoc.target_entity.should eq AssocTarget
    assoc.is_a?(AORM::Mapping::OneToOneOwningSide).should be_true
    assoc.fetch_mode.should eq AORM::Mapping::FetchMode::LAZY
  end

  def test_proxy_typed_property_marks_lazy_proxy : Nil
    metadata = AORM::Mapping::Class(AssocOwner).new
    metadata.map_one_to_one AORM::Mapping::Driver::ColumnMapping.new(field_name: "lazy_target")

    assoc = metadata.association_mappings["lazy_target"].as(AORM::Mapping::OneToOneOwningSide)
    assoc.target_entity.should eq AssocTarget
    assoc.lazy_proxy?.should be_true
  end

  def test_collection_property_infers_target_for_to_many : Nil
    metadata = AORM::Mapping::Class(AssocOwner).new
    metadata.map_one_to_many AORM::Mapping::Driver::ColumnMapping.new(field_name: "collection", mapped_by: "target")

    assoc = metadata.association_mappings["collection"]
    assoc.target_entity.should eq AssocTarget
    assoc.is_a?(AORM::Mapping::OneToManyInverseSide).should be_true
  end

  def test_cascade_all_expands_to_full_set : Nil
    metadata = AORM::Mapping::Class(AssocOwner).new
    metadata.map_one_to_one AORM::Mapping::Driver::ColumnMapping.new(field_name: "target", cascade: ["all"])

    assoc = metadata.association_mappings["target"]
    assoc.cascade.to_set.should eq Set{"remove", "persist", "refresh", "detach"}
  end

  def test_explicit_cascade_passes_through_unchanged : Nil
    metadata = AORM::Mapping::Class(AssocOwner).new
    metadata.map_one_to_one AORM::Mapping::Driver::ColumnMapping.new(field_name: "target", cascade: ["persist"])

    metadata.association_mappings["target"].cascade.should eq ["persist"]
  end

  def test_no_cascade_arg_results_in_empty_cascade : Nil
    metadata = AORM::Mapping::Class(AssocOwner).new
    metadata.map_one_to_one AORM::Mapping::Driver::ColumnMapping.new(field_name: "target")

    metadata.association_mappings["target"].cascade.should be_empty
  end

  def test_mapped_by_routes_to_inverse_side : Nil
    metadata = AORM::Mapping::Class(InverseAssocOwner).new
    metadata.map_many_to_many AORM::Mapping::Driver::ColumnMapping.new(field_name: "collection", mapped_by: "owner")

    assoc = metadata.association_mappings["collection"]
    assoc.is_a?(AORM::Mapping::ManyToManyInverseSide).should be_true
  end

  def test_owning_side_returns_owning_subclass : Nil
    metadata = AORM::Mapping::Class(AssocOwner).new
    metadata.map_many_to_many AORM::Mapping::Driver::ColumnMapping.new(field_name: "collection")

    metadata.association_mappings["collection"].is_a?(AORM::Mapping::ManyToManyOwningSide).should be_true
  end

  def test_many_to_one_with_orphan_removal_raises : Nil
    metadata = AORM::Mapping::Class(AssocOwner).new

    expect_raises Exception, /illegal orphan removal/ do
      metadata.map_many_to_one AORM::Mapping::Driver::ColumnMapping.new(
        field_name: "target", orphan_removal: true
      )
    end
  end

  def test_to_many_with_id_raises : Nil
    metadata = AORM::Mapping::Class(AssocOwner).new

    expect_raises Exception, /illegal to many identifier association/ do
      metadata.map_one_to_many AORM::Mapping::Driver::ColumnMapping.new(
        field_name: "collection", mapped_by: "target", id: true
      )
    end
  end

  def test_association_collides_with_existing_field : Nil
    metadata = AORM::Mapping::Class(AssocOwner).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "target", type: "string")

    expect_raises Exception, /Duplicate field mapping 'target'/ do
      metadata.map_one_to_one AORM::Mapping::Driver::ColumnMapping.new(field_name: "target")
    end
  end

  # ---- primary_table= ----

  def test_primary_table_sets_name : Nil
    metadata = AORM::Mapping::Class(TableQuotingFixture).new
    metadata.primary_table = AORM::Mapping::Driver::TableMapping.new name: "explicit_name"

    metadata.table_name.should eq "explicit_name"
    metadata.table.quoted.should be_false
  end

  def test_primary_table_strips_backticks_and_marks_quoted : Nil
    metadata = AORM::Mapping::Class(TableQuotingFixture).new
    metadata.primary_table = AORM::Mapping::Driver::TableMapping.new name: "`quoted_name`"

    metadata.table_name.should eq "quoted_name"
    metadata.table.quoted.should be_true
  end

  def test_primary_table_sets_schema : Nil
    metadata = AORM::Mapping::Class(TableQuotingFixture).new
    metadata.primary_table = AORM::Mapping::Driver::TableMapping.new name: "t", schema: "s"

    metadata.table.name.should eq "t"
    metadata.table.schema.should eq "s"
  end

  # ---- new_instance / apply_data ----

  def test_new_instance_populates_scalar_fields : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new

    entity = metadata.new_instance({"id" => 5_i64, "label" => "hello"} of String => DB::Any?)
    entity = entity.as(SinglePkFixture)
    entity.id.should eq 5_i64
    entity.label.should eq "hello"
  end

  def test_apply_data_unwraps_mapping_value : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new
    entity = SinglePkFixture.allocate

    metadata.apply_data entity, {
      "id"    => AORM::Mapping::ColumnValue.new("id", 9_i64),
      "label" => AORM::Mapping::ColumnValue.new("label", "wrapped"),
    }

    entity.id.should eq 9_i64
    entity.label.should eq "wrapped"
  end

  def test_apply_data_skips_missing_keys : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new
    entity = SinglePkFixture.new
    entity.label = "preset"

    metadata.apply_data entity, {"id" => 1_i64} of String => DB::Any?
    entity.id.should eq 1_i64
    entity.label.should eq "preset"
  end

  # ---- accessors ----

  def test_type_of_field : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new
    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id")

    metadata.type_of_field("id").should eq "bigint"
    metadata.type_of_field("missing").should be_nil
  end

  def test_column_name_falls_back_to_field_name : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new
    metadata.column_name("not_mapped").should eq "not_mapped"

    metadata.map_field AORM::Mapping::Driver::ColumnMapping.new(field_name: "id", column_name: "pk")
    metadata.column_name("id").should eq "pk"
  end

  def test_table_name_defaults_to_underscored_class_name : Nil
    metadata = AORM::Mapping::Class(TableQuotingFixture).new
    metadata.table_name.should eq "table_quoting_fixture"
  end

  def test_field_value_returns_ivar : Nil
    metadata = AORM::Mapping::Class(SinglePkFixture).new
    entity = SinglePkFixture.new
    entity.id = 99_i64

    metadata.field_value(entity, "id").should eq 99_i64
  end
end
