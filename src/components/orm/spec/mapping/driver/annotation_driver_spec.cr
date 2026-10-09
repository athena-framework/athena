require "../../spec_helper"

# Fixtures for `Annotation#load_metadata_for_entity` end-to-end tests.
# Each fixture is the smallest entity that triggers a single annotation behavior.

@[AORMA::Entity]
class BareEntityFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil
end

@[AORMA::Entity(read_only: true)]
class ReadOnlyEntityFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil
end

@[AORMA::Entity]
@[AORMA::Table("explicit_table")]
class PositionalTableNameFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil
end

@[AORMA::Entity]
@[AORMA::Table(name: "explicit_table")]
class TableNameFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil
end

@[AORMA::Entity]
@[AORMA::Table("explicit_table", schema: "custom_schema")]
class PositionalTableSchemaNameFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil
end

@[AORMA::Entity]
@[AORMA::Table(name: "schema_table", schema: "custom_schema")]
class SchemaTableFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil
end

@[AORMA::Entity]
class FullColumnFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::Column(
    name: "the_name",
    type: "decimal",
    length: 12,
    precision: 10,
    scale: 4,
    unique: true,
    nullable: true,
    index: true,
    column_definition: "DECIMAL(10,4)",
  )]
  property amount : String? = nil

  @[AORMA::Column(updatable: false, insertable: false)]
  property locked : String? = nil
end

@[AORMA::Entity]
class UnmappedTypeFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::Column]
  property initial : Char? = nil
end

@[AORMA::Entity]
class IdentityIdFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :identity)]
  property id : Int64? = nil
end

@[AORMA::Entity]
class AutoIdFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property id : Int64? = nil
end

@[AORMA::Entity]
class NoneIdFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil
end

@[AORMA::Entity]
class DriverAssocTarget < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil
end

@[AORMA::Entity]
class OneToOneOwningFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::OneToOne(cascade: ["persist"], inversed_by: "owner")]
  @[AORMA::JoinColumn(name: "target_fk", referenced_column_name: "id")]
  property target : DriverAssocTarget? = nil
end

@[AORMA::Entity]
class OneToOneInverseFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::OneToOne(mapped_by: "target")]
  property owner : DriverAssocTarget? = nil
end

# Join columns without a join table name, and a join column without a name, get the default names.
@[AORMA::Entity]
class ManyToManyJoinColumnsOnlyFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::ManyToMany]
  @[AORMA::JoinColumn(name: "owner_id")]
  @[AORMA::InverseJoinColumn(referenced_column_name: "id")]
  property targets : AORM::Collection(DriverAssocTarget) = AORM::ArrayCollection(DriverAssocTarget).new
end

@[AORMA::Entity]
class OnDeleteFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::ManyToOne]
  @[AORMA::JoinColumn(name: "target_id", on_delete: "SET NULL")]
  property target : DriverAssocTarget? = nil

  @[AORMA::ManyToMany]
  @[AORMA::JoinTable(name: "on_delete_owner_targets")]
  @[AORMA::JoinColumn(name: "owner_id", on_delete: "CASCADE")]
  @[AORMA::InverseJoinColumn(name: "target_id")]
  property owner_cascading : AORM::Collection(DriverAssocTarget) = AORM::ArrayCollection(DriverAssocTarget).new

  @[AORMA::ManyToMany]
  @[AORMA::JoinTable(name: "on_delete_target_targets")]
  @[AORMA::JoinColumn(name: "owner_id")]
  @[AORMA::InverseJoinColumn(name: "target_id", on_delete: "cascade")]
  property target_cascading : AORM::Collection(DriverAssocTarget) = AORM::ArrayCollection(DriverAssocTarget).new
end

@[AORMA::Entity]
class SelfReferencingManyToManyFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::ManyToMany]
  property friends : AORM::Collection(SelfReferencingManyToManyFixture) = AORM::ArrayCollection(SelfReferencingManyToManyFixture).new
end

@[AORMA::Entity]
class OneToOneInverseProxyFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::OneToOne(mapped_by: "target")]
  property owner : AORM::Proxy(DriverAssocTarget)? = nil
end

@[AORMA::Entity]
class OneToOneInverseIdentifierFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::ID]
  @[AORMA::OneToOne(mapped_by: "target")]
  property owner : DriverAssocTarget? = nil
end

@[AORMA::Entity]
class OneToOneInverseOrphanRemovalFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::OneToOne(mapped_by: "target", orphan_removal: true)]
  property owner : DriverAssocTarget? = nil
end

@[AORMA::Entity]
class ManyToOneFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::ManyToOne(inversed_by: "items")]
  @[AORMA::JoinColumn(name: "parent_id", referenced_column_name: "id")]
  property parent : DriverAssocTarget? = nil
end

@[AORMA::Entity]
class IllegalOrphanRemovalFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::ManyToOne]
  property parent : DriverAssocTarget? = nil
end

@[AORMA::Entity]
class OneToManyInverseFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::OneToMany(mapped_by: "parent", cascade: ["all"], index_by: "id")]
  property children : AORM::Collection(DriverAssocTarget) = AORM::ArrayCollection(DriverAssocTarget).new
end

@[AORMA::Entity]
class ManyToManyOwningFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::ManyToMany(cascade: ["persist"], index_by: "id")]
  @[AORMA::JoinTable(name: "owners_targets", schema: "join_schema")]
  @[AORMA::JoinColumn(name: "owner_fk", referenced_column_name: "id")]
  @[AORMA::InverseJoinColumn(name: "target_fk", referenced_column_name: "id")]
  property targets : AORM::Collection(DriverAssocTarget) = AORM::ArrayCollection(DriverAssocTarget).new
end

@[AORMA::Entity]
class ManyToManyInverseFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::ManyToMany(mapped_by: "targets")]
  property owners : AORM::Collection(DriverAssocTarget) = AORM::ArrayCollection(DriverAssocTarget).new
end

@[AORMA::Entity]
class CompositeJoinColumnFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::ManyToOne]
  @[AORMA::JoinColumn(name: "fk_a", referenced_column_name: "id_a")]
  @[AORMA::JoinColumn(name: "fk_b", referenced_column_name: "id_b")]
  property parent : DriverAssocTarget? = nil
end

@[AORMA::Entity]
class FkAsIdFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::OneToOne]
  @[AORMA::ID]
  @[AORMA::JoinColumn(name: "owner_id", referenced_column_name: "id")]
  property owner : DriverAssocTarget? = nil
end

@[AORMA::Entity]
class NotNullableJoinColumnFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::ManyToOne]
  @[AORMA::JoinColumn(name: "parent_id", referenced_column_name: "id", nullable: false)]
  property parent : DriverAssocTarget? = nil
end

@[AORMA::Entity]
class NullableIdJoinColumnFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::OneToOne]
  @[AORMA::ID]
  @[AORMA::JoinColumn(name: "owner_id", referenced_column_name: "id", nullable: true)]
  property owner : DriverAssocTarget? = nil
end

@[AORMA::Entity(repository_class: CustomDriverRepository)]
class WithCustomRepositoryFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil
end

class CustomDriverRepository < AORM::EntityRepository(WithCustomRepositoryFixture)
end

# An abstract parent without `@[AORMA::Entity]`, sharing its mapped properties with the entities inheriting from it.
abstract class AbstractMappedParentFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property id : Int64? = nil

  @[AORMA::Column(name: "created_by_user")]
  property created_by : String? = nil
end

@[AORMA::Entity]
class AbstractMappedChildFixture < AbstractMappedParentFixture
  @[AORMA::Column]
  property title : String? = nil
end

private def load(entity_class : T.class) : AORM::Mapping::Class(T) forall T
  metadata = AORM::Mapping::Class(T).new
  AORM::Mapping::Driver::Annotation.new.load_metadata_for_entity metadata
  metadata
end

struct AnnotationDriverTest < ASPEC::TestCase
  # ---- @[Entity] ----

  def test_bare_entity_uses_default_table : Nil
    metadata = load BareEntityFixture
    metadata.table_name.should eq "bare_entity_fixture"
    metadata.read_only?.should be_false
    metadata.custom_repository_class.should be_nil
  end

  def test_read_only_flag_set : Nil
    metadata = load ReadOnlyEntityFixture
    metadata.read_only?.should be_true
  end

  def test_custom_repository_class : Nil
    metadata = load WithCustomRepositoryFixture
    metadata.custom_repository_class.should eq CustomDriverRepository
  end

  # ---- @[Table] ----

  def test_explicit_table_name : Nil
    metadata = load TableNameFixture
    metadata.table_name.should eq "explicit_table"
  end

  def test_positional_table_name : Nil
    metadata = load PositionalTableNameFixture
    metadata.table_name.should eq "explicit_table"
  end

  def test_table_with_schema : Nil
    metadata = load SchemaTableFixture
    metadata.table_name.should eq "schema_table"
    metadata.table.schema.should eq "custom_schema"
  end

  def test_positional_table_with_schema : Nil
    metadata = load PositionalTableSchemaNameFixture
    metadata.table_name.should eq "explicit_table"
    metadata.table.schema.should eq "custom_schema"
  end

  # ---- @[Column] translation ----

  def test_column_kwargs_round_trip : Nil
    metadata = load FullColumnFixture
    field = metadata.field_mappings["amount"]
    field.column_name.should eq "the_name"
    field.type.should eq "decimal"
    field.length.should eq 12
    field.precision.should eq 10
    field.scale.should eq 4
    field.unique.should be_true
    field.nullable.should be_true
    field.index.should be_true
    field.column_definition.should eq "DECIMAL(10,4)"
  end

  def test_field_of_an_unmapped_type_without_an_explicit_type_is_rejected : Nil
    expect_raises(Exception, "'UnmappedTypeFixture#initial': no column type is mapped to Char, so pass one with `@[AORMA::Column(type: ...)]`.") do
      load UnmappedTypeFixture
    end
  end

  def test_updatable_false_translates_to_not_updatable : Nil
    metadata = load FullColumnFixture
    field = metadata.field_mappings["locked"]
    field.not_updatable.should be_true
    field.not_insertable.should be_true
  end

  def test_default_column_kwargs_remain_nil_or_default : Nil
    metadata = load BareEntityFixture
    field = metadata.field_mappings["id"]
    field.length.should be_nil
    field.precision.should be_nil
    field.scale.should be_nil
    field.column_definition.should be_nil
    field.generated.should be_nil
    field.enum_type.should be_nil
    field.index.should be_false
  end

  def test_mapped_properties_of_an_abstract_parent_are_inherited : Nil
    metadata = load AbstractMappedChildFixture
    metadata.table_name.should eq "abstract_mapped_child_fixture"
    metadata.field_mappings.keys.should eq ["id", "created_by", "title"]
    metadata.column_name("created_by").should eq "created_by_user"
    metadata.identifier.should eq Set{"id"}
  end

  # ---- @[ID] / @[GeneratedValue] ----

  def test_id_annotation_populates_identifier : Nil
    metadata = load BareEntityFixture
    metadata.identifier.should eq Set{"id"}
    metadata.field_mappings["id"].id.should be_true
  end

  def test_generated_value_default_is_auto : Nil
    metadata = load AutoIdFixture
    metadata.id_generator_type.auto?.should be_true
  end

  def test_generated_value_identity_strategy : Nil
    metadata = load IdentityIdFixture
    metadata.id_generator_type.identity?.should be_true
  end

  def test_no_generated_value_keeps_strategy_none : Nil
    metadata = load NoneIdFixture
    metadata.id_generator_type.none?.should be_true
  end

  # ---- @[OneToOne] / @[ManyToOne] / @[OneToMany] / @[ManyToMany] dispatch ----

  def test_one_to_one_owning_dispatch : Nil
    metadata = load OneToOneOwningFixture
    assoc = metadata.association_mappings["target"]
    assoc.is_a?(AORM::Mapping::OneToOneOwningSide).should be_true
    assoc.target_entity.should eq DriverAssocTarget
    assoc.cascade.should eq ["persist"]
    assoc.as(AORM::Mapping::OneToOneOwningSide).inversed_by.should eq "owner"
  end

  def test_one_to_one_inverse_dispatch : Nil
    metadata = load OneToOneInverseFixture
    assoc = metadata.association_mappings["owner"].as(AORM::Mapping::OneToOneInverseSide)
    assoc.mapped_by.should eq "target"
    assoc.target_entity.should eq DriverAssocTarget
  end

  def test_many_to_one_dispatch : Nil
    metadata = load ManyToOneFixture
    assoc = metadata.association_mappings["parent"].as(AORM::Mapping::ManyToOneOwningSide)
    assoc.target_entity.should eq DriverAssocTarget
    assoc.inversed_by.should eq "items"
  end

  # The inverse side never holds the target's identifier, so it can't be loaded lazily from it.
  def test_one_to_one_inverse_side_rejects_proxy_typing : Nil
    expect_raises(Exception, "AORM::Proxy(T) is only valid on owning-side ToOne fields; field 'owner' on 'OneToOneInverseProxyFixture' is the inverse side") do
      load OneToOneInverseProxyFixture
    end
  end

  def test_one_to_one_inverse_side_cannot_be_part_of_the_identifier : Nil
    expect_raises(Exception, "An inverse association is not allowed to be identifier in 'OneToOneInverseIdentifierFixture#owner'.") do
      load OneToOneInverseIdentifierFixture
    end
  end

  def test_one_to_one_inverse_side_orphan_removal_cascades_remove : Nil
    metadata = load OneToOneInverseOrphanRemovalFixture
    assoc = metadata.association_mappings["owner"].as(AORM::Mapping::OneToOneInverseSide)
    assoc.orphan_removal?.should be_true
    assoc.cascade_remove?.should be_true
  end

  def test_many_to_many_join_columns_without_names_get_defaults : Nil
    metadata = load ManyToManyJoinColumnsOnlyFixture
    join_table = metadata.association_mappings["targets"].as(AORM::Mapping::ManyToManyOwningSide).join_table.not_nil!

    join_table.name.should eq "many_to_many_join_columns_only_fixture_driver_assoc_target"
    join_table.join_columns.map(&.name).should eq ["owner_id"]
    join_table.inverse_join_columns.map(&.name).should eq ["driver_assoc_target_id"]
  end

  # Default join columns are `ON DELETE CASCADE`, which the persister relies on to delete a removed entity's join table rows.
  def test_many_to_many_default_join_columns_cascade_on_delete : Nil
    assoc = load(SelfReferencingManyToManyFixture).association_mappings["friends"].as(AORM::Mapping::ManyToManyOwningSide)
    join_table = assoc.join_table.not_nil!

    assoc.on_delete_cascade?.should be_true
    (join_table.join_columns + join_table.inverse_join_columns).map(&.on_delete).should eq ["CASCADE", "CASCADE"]
  end

  def test_many_to_many_explicit_join_columns_dont_cascade_on_delete : Nil
    load(ManyToManyOwningFixture).association_mappings["targets"].as(AORM::Mapping::ManyToManyOwningSide).on_delete_cascade?.should be_false
  end

  def test_to_one_join_column_on_delete : Nil
    assoc = load(OnDeleteFixture).association_mappings["target"].as(AORM::Mapping::ManyToOneOwningSide)

    assoc.join_columns.map(&.on_delete).should eq ["SET NULL"]
  end

  # Either join column cascading on delete means the database deletes a removed entity's join table rows.
  def test_many_to_many_join_column_on_delete_cascade : Nil
    metadata = load OnDeleteFixture

    owner_cascading = metadata.association_mappings["owner_cascading"].as(AORM::Mapping::ManyToManyOwningSide)
    owner_cascading.join_table.not_nil!.join_columns.map(&.on_delete).should eq ["CASCADE"]
    owner_cascading.on_delete_cascade?.should be_true

    metadata.association_mappings["target_cascading"].as(AORM::Mapping::ManyToManyOwningSide).on_delete_cascade?.should be_true
  end

  # Both default join columns would be named after the same entity, so they're suffixed `_source` and `_target` instead.
  def test_self_referencing_many_to_many_default_join_columns : Nil
    metadata = load SelfReferencingManyToManyFixture
    assoc = metadata.association_mappings["friends"].as(AORM::Mapping::ManyToManyOwningSide)
    join_table = assoc.join_table.not_nil!

    join_table.name.should eq "self_referencing_many_to_many_fixture_self_referencing_many_to_many_fixture"
    join_table.join_columns.map(&.name).should eq ["self_referencing_many_to_many_fixture_source"]
    join_table.inverse_join_columns.map(&.name).should eq ["self_referencing_many_to_many_fixture_target"]
    assoc.relation_to_source_key_columns.should eq({"self_referencing_many_to_many_fixture_source" => "id"})
    assoc.relation_to_target_key_columns.should eq({"self_referencing_many_to_many_fixture_target" => "id"})
  end

  def test_one_to_many_inverse_dispatch : Nil
    metadata = load OneToManyInverseFixture
    assoc = metadata.association_mappings["children"].as(AORM::Mapping::OneToManyInverseSide)
    assoc.mapped_by.should eq "parent"
    assoc.target_entity.should eq DriverAssocTarget
    assoc.cascade.to_set.should eq Set{"remove", "persist", "refresh", "detach"}
    assoc.index_by.should eq "id"
  end

  def test_many_to_many_owning_dispatch : Nil
    metadata = load ManyToManyOwningFixture
    assoc = metadata.association_mappings["targets"].as(AORM::Mapping::ManyToManyOwningSide)
    assoc.target_entity.should eq DriverAssocTarget
    assoc.cascade.should eq ["persist"]
    assoc.index_by.should eq "id"
  end

  def test_many_to_many_inverse_dispatch : Nil
    metadata = load ManyToManyInverseFixture
    assoc = metadata.association_mappings["owners"].as(AORM::Mapping::ManyToManyInverseSide)
    assoc.mapped_by.should eq "targets"
  end

  def test_many_to_one_orphan_removal_not_supported : Nil
    # `@[AORMA::ManyToOne]` annotation does not accept `orphan_removal` (no kwarg defined),
    # so the illegal-orphan-removal raise can only be reached via direct `map_many_to_one` calls.
    # Locked in by `class_spec.cr:test_many_to_one_with_orphan_removal_raises`; this guard documents
    # that the driver path can't trigger it under the current annotation surface.
    load(IllegalOrphanRemovalFixture).association_mappings["parent"]
      .as(AORM::Mapping::ManyToOneOwningSide).orphan_removal?.should be_false
  end

  # ---- @[JoinColumn] / @[InverseJoinColumn] / @[JoinTable] ----

  def test_one_to_one_join_column_picked_up : Nil
    metadata = load OneToOneOwningFixture
    assoc = metadata.association_mappings["target"].as(AORM::Mapping::OneToOneOwningSide)
    jc = assoc.join_columns.first
    jc.name.should eq "target_fk"
    jc.referenced_column_name.should eq "id"
  end

  def test_many_to_one_join_column_picked_up : Nil
    metadata = load ManyToOneFixture
    assoc = metadata.association_mappings["parent"].as(AORM::Mapping::ManyToOneOwningSide)
    jc = assoc.join_columns.first
    jc.name.should eq "parent_id"
    jc.referenced_column_name.should eq "id"
  end

  def test_multiple_join_columns_preserve_order : Nil
    metadata = load CompositeJoinColumnFixture
    assoc = metadata.association_mappings["parent"].as(AORM::Mapping::ManyToOneOwningSide)
    assoc.join_columns.size.should eq 2
    assoc.join_columns.map(&.name).should eq ["fk_a", "fk_b"]
    assoc.join_columns.map(&.referenced_column_name).should eq ["id_a", "id_b"]
  end

  def test_many_to_many_join_table_and_columns : Nil
    metadata = load ManyToManyOwningFixture
    assoc = metadata.association_mappings["targets"].as(AORM::Mapping::ManyToManyOwningSide)
    join_table = assoc.join_table.not_nil!
    join_table.name.should eq "owners_targets"
    join_table.schema.should eq "join_schema"
    join_table.join_columns.map(&.name).should eq ["owner_fk"]
    join_table.inverse_join_columns.map(&.name).should eq ["target_fk"]
  end

  def test_fk_as_pk_marks_association_id : Nil
    metadata = load FkAsIdFixture
    assoc = metadata.association_mappings["owner"]
    assoc.id?.should be_true
  end

  def test_to_one_join_column_defaults_to_nullable : Nil
    metadata = load ManyToOneFixture
    assoc = metadata.association_mappings["parent"].as(AORM::Mapping::ManyToOneOwningSide)
    assoc.join_columns.first.nullable.should be_true
  end

  def test_to_one_join_column_honors_explicit_not_nullable : Nil
    metadata = load NotNullableJoinColumnFixture
    assoc = metadata.association_mappings["parent"].as(AORM::Mapping::ManyToOneOwningSide)
    assoc.join_columns.first.nullable.should be_false
  end

  # A foreign key that is part of the primary key can never be NULL.
  def test_to_one_identifier_join_column_is_not_nullable : Nil
    metadata = load FkAsIdFixture
    assoc = metadata.association_mappings["owner"].as(AORM::Mapping::OneToOneOwningSide)
    assoc.join_columns.first.nullable.should be_false
  end

  def test_to_one_identifier_join_column_rejects_explicit_nullable : Nil
    expect_raises(Exception, /cannot set nullable/) do
      load NullableIdJoinColumnFixture
    end
  end

  # ---- shared model fixtures load cleanly ----

  def test_existing_cms_user_loads : Nil
    metadata = load CmsUser
    metadata.table_name.should_not be_empty
    metadata.identifier.should_not be_empty
  end
end
