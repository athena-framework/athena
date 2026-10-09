require "../../spec_helper"

# Friend subclass that exposes the protected SQL/param helpers so we can
# assert their output without driving a real DB exec.
private class TestableManyToManyPersister < AORM::Persisters::Collection::ManyToManyPersister
  def public_get_delete_sql(mapping)
    self.get_delete_sql mapping
  end

  def public_get_delete_row_sql(mapping)
    self.get_delete_row_sql mapping
  end

  def public_get_insert_row_sql(mapping)
    self.get_insert_row_sql mapping
  end

  def public_get_delete_sql_params(collection, mapping)
    self.get_delete_sql_params collection, mapping
  end

  def public_get_delete_row_sql_params(collection, element, mapping)
    self.get_delete_row_sql_params collection, element, mapping
  end

  def public_get_insert_row_sql_params(collection, element, mapping)
    self.get_insert_row_sql_params collection, element, mapping
  end

  def public_valid_entity_state?(entity)
    self.valid_entity_state? entity
  end
end

struct ManyToManyPersisterTest < ASPEC::TestCase
  # ===== SQL generation =====

  def test_get_delete_sql_targets_join_table_with_owner_key_in_where : Nil
    persister = build_persister
    mapping = cms_user_groups_mapping

    sql = persister.public_get_delete_sql mapping

    sql.should eq "DELETE FROM cms_user_cms_group WHERE cms_user_id = ?"
  end

  def test_get_delete_row_sql_includes_owner_and_element_keys : Nil
    persister = build_persister
    mapping = cms_user_groups_mapping

    sql, types = persister.public_get_delete_row_sql mapping

    sql.should eq "DELETE FROM cms_user_cms_group WHERE cms_user_id = ? AND cms_group_id = ?"
    types.should eq ["integer", "integer"]
  end

  def test_get_insert_row_sql_lists_join_columns_in_order : Nil
    persister = build_persister
    mapping = cms_user_groups_mapping

    sql, types = persister.public_get_insert_row_sql mapping

    sql.should eq "INSERT INTO cms_user_cms_group (cms_user_id, cms_group_id) VALUES (?, ?)"
    types.should eq ["integer", "integer"]
  end

  # ===== Parameter binding =====

  def test_get_delete_sql_params_returns_owner_identifier : Nil
    persister, mapping = build_persister_with_mapping
    user = managed_user 100

    collection = AORM::PersistentCollection(CmsGroup).new
    collection.set_owner user, mapping

    params = persister.public_get_delete_sql_params collection, mapping

    params.map(&.value).should eq [100]
  end

  def test_get_delete_row_sql_params_pairs_owner_then_element_ids : Nil
    persister, mapping = build_persister_with_mapping
    user = managed_user 7
    group = managed_group 99

    collection = AORM::PersistentCollection(CmsGroup).new
    collection.set_owner user, mapping

    params = persister.public_get_delete_row_sql_params collection, group, mapping

    # Source key columns precede target key columns — must match the order in
    # the generated SQL so positional placeholders bind correctly.
    params.map(&.value).should eq [7, 99]
  end

  def test_get_insert_row_sql_params_uses_same_ordering_as_delete : Nil
    persister, mapping = build_persister_with_mapping
    user = managed_user 1
    group = managed_group 2

    collection = AORM::PersistentCollection(CmsGroup).new
    collection.set_owner user, mapping

    params = persister.public_get_insert_row_sql_params collection, group, mapping

    params.map(&.value).should eq [1, 2]
  end

  # ===== Value conversion =====

  def test_update_binds_inserted_rows_converted_through_the_identifier_types : Nil
    _owner, element, collection = build_value_conversion_collection
    collection << element

    build_persister.update collection

    @connection.executed_statements.last.should eq({"INSERT INTO vct_xref_manytomany (owning_id, inversed_id) VALUES (?, ?)", ["nop", "qrs"]})
  end

  def test_update_binds_deleted_rows_converted_through_the_identifier_types : Nil
    _owner, element, collection = build_value_conversion_collection
    collection << element
    collection.take_snapshot
    collection.remove_element element

    build_persister.update collection

    @connection.executed_statements.last.should eq({"DELETE FROM vct_xref_manytomany WHERE owning_id = ? AND inversed_id = ?", ["nop", "qrs"]})
  end

  def test_delete_binds_the_owner_identifier_converted_through_its_type : Nil
    _owner, _element, collection = build_value_conversion_collection

    build_persister.delete collection

    @connection.executed_statements.last.should eq({"DELETE FROM vct_xref_manytomany WHERE owning_id = ?", ["nop"]})
  end

  def test_update_binds_value_object_identifiers_converted_through_their_type : Nil
    mapping = @em.class_metadata(CustomIdObjectTypeParent).association_mappings["tags"].as(AORM::Mapping::ManyToManyOwningSide)

    parent = CustomIdObjectTypeParent.new
    parent.id = CustomIdObject.new "abc"
    @uow.register_managed parent, {"id" => parent.id}, {"id" => parent.id}

    tag = CustomIdObjectTypeTag.new
    tag.id = CustomIdObject.new "red"
    @uow.register_managed tag, {"id" => tag.id}, {"id" => tag.id}

    collection = AORM::PersistentCollection(CustomIdObjectTypeTag).new
    collection.set_owner parent, mapping
    collection << tag

    build_persister.update collection

    @connection.executed_statements.last.should eq({"INSERT INTO custom_id_type_parent_tag (parent_id, tag_id) VALUES (?, ?)", ["abc", "red"]})
  end

  # ===== Setup helpers =====

  private def build_value_conversion_collection : {ValueConversionType::OwningManyToManyEntity, ValueConversionType::InversedManyToManyEntity, AORM::PersistentCollection(ValueConversionType::InversedManyToManyEntity)}
    mapping = @em.class_metadata(ValueConversionType::OwningManyToManyEntity).association_mappings["associated_entities"].as(AORM::Mapping::ManyToManyOwningSide)

    owner = ValueConversionType::OwningManyToManyEntity.new
    owner.id2 = "abc"
    @uow.register_managed owner, {"id2" => "abc"}, {"id2" => "abc"}

    element = ValueConversionType::InversedManyToManyEntity.new
    element.id1 = "def"
    @uow.register_managed element, {"id1" => "def"}, {"id1" => "def"}

    collection = AORM::PersistentCollection(ValueConversionType::InversedManyToManyEntity).new
    collection.set_owner owner, mapping

    {owner, element, collection}
  end

  # ===== Entity state =====

  def test_managed_entity_is_in_a_valid_state : Nil
    build_persister.public_valid_entity_state?(managed_group(1)).should be_true
  end

  def test_new_entity_is_not_in_a_valid_state : Nil
    build_persister.public_valid_entity_state?(CmsGroup.new).should be_false
  end

  # An entity scheduled for insertion can't be in a collection that's already in the database.
  def test_entity_scheduled_for_insertion_is_not_in_a_valid_state : Nil
    group = CmsGroup.new
    group.name = "new"
    @uow.persist group

    build_persister.public_valid_entity_state?(group).should be_false
  end

  private def build_persister : TestableManyToManyPersister
    TestableManyToManyPersister.new @em
  end

  private def build_persister_with_mapping : {TestableManyToManyPersister, AORM::Mapping::ManyToManyOwningSide}
    {build_persister, cms_user_groups_mapping}
  end

  private def cms_user_groups_mapping : AORM::Mapping::ManyToManyOwningSide
    @em.class_metadata(CmsUser).association_mappings["groups"].as(AORM::Mapping::ManyToManyOwningSide)
  end

  private def managed_user(id : Int32) : CmsUser
    user = CmsUser.new
    user.username = "u#{id}"
    user.id = id
    @uow.register_managed user, {"id" => id}, {"id" => id}
    user
  end

  private def managed_group(id : Int32) : CmsGroup
    group = CmsGroup.new
    group.name = "g#{id}"
    group.id = id
    @uow.register_managed group, {"id" => id}, {"id" => id}
    group
  end

  @connection : MockConnection
  @em : MockEntityManager
  @uow : AORM::UnitOfWork

  def initialize
    @connection = MockConnection.new
    @em = MockEntityManager.new(@connection)
    @uow = @em.unit_of_work
  end
end
